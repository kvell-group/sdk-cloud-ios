// DevLogStore.swift
// KvellDevKit — dev-only, не распространяется.
//
// In-memory журнал dev-логов. LoggingNetworkDispatcher пишет сюда каждую строку,
// демо-приложение показывает журнал на экране Logs — так сырые HTTP-логи видны
// прямо на устройстве/симуляторе без подключённой консоли Xcode.

import Foundation

public final class DevLogStore {

    public static let shared = DevLogStore()

    /// Постится после каждого append/clear. Может прийти с фонового потока —
    /// подписчик сам переключается на main.
    public static let didChangeNotification = Notification.Name("KvellDevLogStoreDidChange")

    /// Защита от разрастания при долгих сессиях: старые строки вытесняются.
    private let maxLines = 5000

    private let queue = DispatchQueue(label: "io.kvell.devkit.logstore")
    private var lines: [String] = []

    public init() {}

    public func append(_ line: String) {
        queue.sync {
            lines.append(line)
            if lines.count > maxLines {
                lines.removeFirst(lines.count - maxLines)
            }
        }
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }

    public var text: String {
        queue.sync { lines.joined(separator: "\n") }
    }

    public var isEmpty: Bool {
        queue.sync { lines.isEmpty }
    }

    public func clear() {
        queue.sync { lines.removeAll() }
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }
}
