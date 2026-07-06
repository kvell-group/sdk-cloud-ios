// LoggingNetworkDispatcher.swift
// KvellDevKit — dev-only, не распространяется.
//
// Оборачивает реальный сетевой диспетчер и логирует сырые request/response
// (URL, метод, заголовки, тело, статус, тело ответа) в три места:
// stdout (консоль Xcode), DevLogStore (экран Logs в демо-приложении) и,
// опционально, файл по пути из переменной окружения `KVELL_DEV_LOG_PATH` —
// так лог надёжно снимается с симулятора без перехвата консоли. Используется
// при тестировании против живого бэка, особенно ошибок, где сырое тело ответа
// теряется на этапе декодирования модели.

import Foundation
import KvellNetworking

public final class LoggingNetworkDispatcher: KvellNetworkDispatcher {

    private let wrapped: KvellNetworkDispatcher

    private static let logURL: URL? = {
        guard let path = ProcessInfo.processInfo.environment["KVELL_DEV_LOG_PATH"] else { return nil }
        return URL(fileURLWithPath: path)
    }()

    /// Дозапись в файл сериализуется: конкурентные request/response-колбэки
    /// не должны гонять на создании файла и позиции дозаписи.
    private static let fileQueue = DispatchQueue(label: "io.kvell.devkit.logfile")

    public init(wrapping wrapped: KvellNetworkDispatcher = KvellURLSessionNetworkDispatcher.instance) {
        self.wrapped = wrapped
    }

    // MARK: - Emit

    private func emit(_ s: String) {
        print(s)
        DevLogStore.shared.append(s)
        guard let url = Self.logURL, let data = (s + "\n").data(using: .utf8) else { return }
        Self.fileQueue.async {
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            } else {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    // MARK: - Logging

    private func logRequest(_ request: KvellRequest) {
        emit("\n┌──────── HTTP REQUEST ────────")
        emit("│ \(request.method.rawValue) \(request.path)")
        emit("│ Headers: \(redacted(request.headers))")
        if let body = request.body, let s = String(data: body, encoding: .utf8) {
            emit("│ Body: \(s)")
        } else if !request.params.isEmpty {
            let clean = request.params.compactMapValues { $0 }
            if let d = try? JSONSerialization.data(withJSONObject: clean, options: [.prettyPrinted, .sortedKeys]),
               let s = String(data: d, encoding: .utf8) {
                emit("│ Body(params):\n\(s)")
            } else {
                emit("│ Body(params): \(clean)")
            }
        }
        emit("└──────────────────────────────")
    }

    private func logResponse(status: Int?, data: Data?, error: Error?) {
        emit("\n┌──────── HTTP RESPONSE ───────")
        if let status = status { emit("│ Status: \(status)") }
        if let error = error { emit("│ Error: \(error.localizedDescription)") }
        if let data = data, let s = String(data: data, encoding: .utf8) {
            emit("│ Body: \(s)")
        } else if data == nil {
            emit("│ Body: <none>")
        }
        emit("└──────────────────────────────")
    }

    /// Маскируем значение Authorization, оставляя схему — чтобы лог можно было показать, не светя секрет.
    private func redacted(_ headers: [String: String]) -> [String: String] {
        var out = headers
        if let auth = out["Authorization"] {
            let scheme = auth.split(separator: " ").first.map(String.init) ?? "***"
            out["Authorization"] = "\(scheme) <redacted>"
        }
        return out
    }

    // MARK: - KvellNetworkDispatcher

    public func dispatch(request: KvellRequest,
                         onSuccess: @escaping (Data) -> Void,
                         onError: @escaping (Error) -> Void,
                         onRedirect: ((URLRequest) -> Bool)?) {
        logRequest(request)
        wrapped.dispatch(request: request, onSuccess: { [weak self] data in
            self?.logResponse(status: nil, data: data, error: nil)
            onSuccess(data)
        }, onError: { [weak self] error in
            self?.logResponse(status: nil, data: nil, error: error)
            onError(error)
        }, onRedirect: onRedirect)
    }

    public func dispatchWithStatusCode(request: KvellRequest,
                                       onSuccess: @escaping (Int, Data) -> Void,
                                       onError: @escaping (Error, Int) -> Void,
                                       onRedirect: ((URLRequest) -> Bool)?) {
        logRequest(request)
        wrapped.dispatchWithStatusCode(request: request, onSuccess: { [weak self] status, data in
            self?.logResponse(status: status, data: data, error: nil)
            onSuccess(status, data)
        }, onError: { [weak self] error, status in
            self?.logResponse(status: status, data: nil, error: error)
            onError(error, status)
        }, onRedirect: onRedirect)
    }
}
