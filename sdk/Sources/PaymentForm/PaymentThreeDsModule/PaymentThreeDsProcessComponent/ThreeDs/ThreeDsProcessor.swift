//
//  ThreeDsProcessor.swift
//  sdk
//
//  Created by Kvell on 16.12.2025.
//  Copyright © 2025 Kvell. All rights reserved.
//

import WebKit

public protocol ThreeDsDelegate: AnyObject  {
    func willPresentWebView(_ webView: WKWebView)
    func onAuthorizationCompleted(with md: String, paRes: String)
    func onAuthorizationFailed(with html: String)
}

public class ThreeDsProcessor: NSObject, WKNavigationDelegate {
    // TermUrl — маркер завершения 3DS. Реального сервера за ним нет и не требуется:
    // навигация на него перехватывается в decidePolicyFor до DNS-резолва,
    // а PaRes/MD достаются из query редиректа или из полей формы страницы-отправителя.
    private static let POST_BACK_URL = "https://api.pay-pulse.example/payments/get3dsData"

    // Фактический финал 3DS у гейтвея pay-pulse: /3ds/return отдаёт страницу
    // с автосабмит-формой POST(PaRes, MD) на PaymentUrl из charge-запроса
    // (kvell://sdk.pay-pulse.com — см. KvellApi.charge). Кастомную схему
    // WKWebView загрузить не может — перехватываем её так же, как TermUrl.
    private static let PAYMENT_URL_SCHEME = "kvell"
    
    private weak var delegate: ThreeDsDelegate?

    /// 3DS завершается ровно один раз: гейт от двойного completion
    /// (повторный редирект финала или ошибка навигации после успеха).
    private var didComplete = false

    public func make3DSPayment(with data: ThreeDsData, delegate: ThreeDsDelegate) {
        self.delegate = delegate
        didComplete = false
        
        if let url = URL.init(string: data.acsUrl) {
            var request = URLRequest.init(url: url)
            request.httpMethod = "POST"
            request.cachePolicy = .reloadIgnoringCacheData
            
            let requestBody = String.init(format: "MD=%@&PaReq=%@&TermUrl=%@", data.transactionId, data.paReq, ThreeDsProcessor.POST_BACK_URL).replacingOccurrences(of: "+", with: "%2B")
            request.httpBody = requestBody.data(using: .utf8)
            
            URLCache.shared.removeCachedResponse(for: request)
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else {
                    return
                }

                if let error = error {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self, !self.didComplete else { return }
                        self.didComplete = true
                        self.delegate?.onAuthorizationFailed(with: "Unable to load 3DS autorization page.\n\(error.localizedDescription)")

                        LoggerService.shared.logApiRequest(method: request.httpMethod ?? "", url: url.absoluteString, success: false)
                    }
                    return
                }

                if let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 200 || httpResponse.statusCode == 201), let data = data {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                            return
                        }
                        
                        LoggerService.shared.logApiRequest(method: request.httpMethod ?? "", url: url.absoluteString, success: true)
                        
                        let webView = WKWebView.init()
                        webView.navigationDelegate = self
                        if let mimeType = httpResponse.mimeType,
                           let url = httpResponse.url {
                            
                            let textEncodingName = httpResponse.textEncodingName ?? ""
                            webView.load(data, mimeType: mimeType, characterEncodingName: textEncodingName, baseURL: url)
                        }
                        
                        self.delegate?.willPresentWebView(webView)
                    }
                } else if let httpResponse = response as? HTTPURLResponse {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self, !self.didComplete else { return }
                        self.didComplete = true
                        self.delegate?.onAuthorizationFailed(with: "Unable to load 3DS autorization page.\nStatus code: \(httpResponse.statusCode)")

                        LoggerService.shared.logApiRequest(method: request.httpMethod ?? "", url: url.absoluteString, success: false)
                    }
                }
            }.resume()
        }
    }

    //MARK: - WKNavigationDelegate -

    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url,
              url.absoluteString.hasPrefix(ThreeDsProcessor.POST_BACK_URL)
                || url.scheme?.lowercased() == ThreeDsProcessor.PAYMENT_URL_SCHEME else {
            decisionHandler(.allow)
            return
        }

        // Финал 3DS: гейтвей вернул браузер на TermUrl. Загружать нечего —
        // забираем PaRes/MD и отменяем навигацию.
        decisionHandler(.cancel)

        guard !didComplete else { return }

        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let paRes = items.first(where: { $0.name.caseInsensitiveCompare("PaRes") == .orderedSame })?.value,
           let md = items.first(where: { $0.name.caseInsensitiveCompare("MD") == .orderedSame })?.value {
            print("3DS TermUrl intercepted: PaRes in query")
            didComplete = true
            delegate?.onAuthorizationCompleted(with: md, paRes: paRes)
            return
        }

        // PaRes отправлен form-POST'ом: тело запроса из WKNavigationAction недоступно,
        // но страница-отправитель ещё загружена — читаем значения её полей.
        let script = """
        (function() {
            var read = function(name) {
                var el = document.querySelector('[name="' + name + '"]');
                return el ? el.value : null;
            };
            return JSON.stringify({MD: read('MD') || read('md'), PaRes: read('PaRes') || read('pares')});
        })()
        """
        webView.evaluateJavaScript(script) { [weak self] result, _ in
            guard let self = self, !self.didComplete else { return }
            self.didComplete = true

            if let json = result as? String,
               let data = json.data(using: .utf8),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let md = dict["MD"] as? String,
               let paRes = dict["PaRes"] as? String {
                print("3DS TermUrl intercepted: PaRes in form post")
                self.delegate?.onAuthorizationCompleted(with: md, paRes: paRes)
            } else {
                self.delegate?.onAuthorizationFailed(with: "3DS finished without PaRes: \(url.absoluteString)")
            }
        }
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        reportNavigationError(error)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        reportNavigationError(error)
    }

    /// Раньше ошибка навигации молча оставляла webview на спиннере — теперь завершает 3DS с ошибкой.
    private func reportNavigationError(_ error: Error) {
        let nsError = error as NSError
        // NSURLErrorCancelled — наш собственный .cancel из decidePolicyFor, не ошибка.
        guard nsError.code != NSURLErrorCancelled, !didComplete else { return }
        didComplete = true
        delegate?.onAuthorizationFailed(with: "3DS navigation failed: \(error.localizedDescription)")
    }
}

