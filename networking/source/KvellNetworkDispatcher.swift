//
//  KvellURLSessionNetworkDispatcher.swift
//  Kvell
//
//  Created by Kvell on 01.07.2021.
//

import Foundation

public protocol KvellNetworkDispatcher {
    func dispatch(request: KvellRequest,
                  onSuccess: @escaping (Data) -> Void,
                  onError: @escaping (Error) -> Void,
                  onRedirect: ((URLRequest) -> Bool)?)
    
    func dispatchWithStatusCode(request: KvellRequest,
                                onSuccess: @escaping (Int, Data) -> Void,
                                onError: @escaping (Error, Int) -> Void,
                                onRedirect: ((URLRequest) -> Bool)?)
}

public class KvellURLSessionNetworkDispatcher: NSObject, KvellNetworkDispatcher {
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)

    public static let instance = KvellURLSessionNetworkDispatcher()

    private var onRedirect: ((URLRequest) -> Bool)?

    public var requestSigner: ((Data?) -> [String: String])?

    public func dispatch(request: KvellRequest,
                         onSuccess: @escaping (Data) -> Void,
                         onError: @escaping (Error) -> Void,
                         onRedirect: ((URLRequest) -> Bool)? = nil) {
        self.onRedirect = onRedirect
        
        guard let url = URL(string: request.path) else {
            onError(KvellConnectionError.invalidURL)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue

        let bodyData: Data?
        if let body = request.body {
            bodyData = body
            print("[dispatch] Используется кастомный body (Data), длина: \(body.count) байт")
        } else if request.method != .get && !request.params.isEmpty {
            do {
                bodyData = try JSONSerialization.data(withJSONObject: request.params, options: [])
                print("[dispatch] Сериализованное тело из params: \(request.params)")
                if let json = String(data: bodyData ?? Data(), encoding: .utf8) {
                    print("------------>>>>> Final JSON:\n\(json)")
                }
            } catch let error {
                print("[dispatch] Ошибка сериализации параметров: \(error.localizedDescription)")
                onError(error)
                return
            }
        } else {
            bodyData = nil
            print("[dispatch] Метод \(request.method.rawValue) — тело запроса не добавляется.")
        }
        urlRequest.httpBody = bodyData

        var headers = request.headers
        if headers["User-Agent"] == nil {
            headers["User-Agent"] = "Mobile_SDK_iOS"
        }
        headers["Content-Type"] = headers["Content-Type"] ?? "application/json"
        if let signer = requestSigner {
            let signerHeaders = signer(bodyData)
            for (key, value) in signerHeaders {
                headers[key] = value
            }
        }
        urlRequest.allHTTPHeaderFields = headers
        
        print("[dispatch] Заголовки запроса: \(urlRequest.allHTTPHeaderFields ?? [:])")
        print("[dispatch] \(request.method) → \(urlRequest.url?.absoluteString ?? "")")
        
        session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("[dispatch] Ошибка: \(error.localizedDescription)")
                onError(error)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[dispatch] HTTP Status Code: \(httpResponse.statusCode)")
                print("[dispatch] HTTP Headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let data = data else {
                print("[dispatch] Нет данных в ответе")
                onError(KvellConnectionError.noData)
                return
            }
            
            onSuccess(data)
        }.resume()
    }
    
    public func dispatchWithStatusCode(request: KvellRequest,
                                       onSuccess: @escaping (Int, Data) -> Void,
                                       onError: @escaping (Error, Int) -> Void,
                                       onRedirect: ((URLRequest) -> Bool)? = nil) {
        performRequest(request: request, returnStatusCode: true, onSuccess: onSuccess, onError: onError, onRedirect: onRedirect)
    }
    
    private func performRequest(request: KvellRequest,
                                returnStatusCode: Bool,
                                onSuccess: @escaping (Int, Data) -> Void,
                                onError: @escaping (Error, Int) -> Void,
                                onRedirect: ((URLRequest) -> Bool)? = nil) {
        guard let url = URL(string: request.path) else {
            onError(KvellConnectionError.invalidURL, 0)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue

        let bodyData: Data? = request.params.isEmpty ? nil : try? JSONSerialization.data(withJSONObject: request.params, options: [])
        urlRequest.httpBody = bodyData

        var headers = request.headers
        headers["Content-Type"] = "application/json"
        headers["User-Agent"] = "Mobile_SDK_iOS"
        if let signer = requestSigner {
            let signerHeaders = signer(bodyData)
            for (key, value) in signerHeaders {
                headers[key] = value
            }
        }
        urlRequest.allHTTPHeaderFields = headers
        
        session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                onError(error, 0)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                onError(KvellConnectionError.noData, 0)
                return
            }
            
            let statusCode = httpResponse.statusCode
            guard let data = data else {
                onError(KvellConnectionError.noData, statusCode)
                return
            }
            
            if returnStatusCode {
                onSuccess(statusCode, data)
            } else {
                onSuccess(0, data)
            }
        }.resume()
    }
}

extension KvellURLSessionNetworkDispatcher: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        if let _ = onRedirect?(request) {
            completionHandler(request)
        } else {
            completionHandler(nil)
        }
    }
}
