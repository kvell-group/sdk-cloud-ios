import Foundation

/// Конфигурация dev-окружения. Dev-only — не включать в распространяемый SDK.
public enum DevConfig {

    /// Секрет подписи из переменной окружения `KVELL_DEV_SIGN_SECRET`.
    /// Задаётся через Xcode Scheme → Environment Variables, или экспортируется перед сборкой.
    /// Если переменная не задана — возвращается пустая строка (подпись будет некорректна).
    public static let signSecret: String =
        ProcessInfo.processInfo.environment["KVELL_DEV_SIGN_SECRET"] ?? ""

    /// Base URL dev/prod окружения.
    public static let devBaseURL: String = "https://business.prod.pay-pulse.com/"
}
