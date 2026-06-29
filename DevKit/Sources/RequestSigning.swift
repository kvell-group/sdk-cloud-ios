import Foundation
import CryptoKit

/// Фабрика замыкания для подписи запросов. Dev-only.
///
/// Использование:
/// ```swift
/// KvellURLSessionNetworkDispatcher.instance.requestSigner =
///     makeRequestSigner(secret: DevConfig.signSecret)
/// ```
public func makeRequestSigner(secret: String) -> (Data?) -> [String: String] {
    return { body in
        let bodyData = body ?? Data()
        let hash = SHA256.hash(data: bodyData)
        let bodyHash = hash.map { String(format: "%02x", $0) }.joined()

        let now = Int(Date().timeIntervalSince1970)
        let payload: [String: Any] = [
            "body_hash": bodyHash,
            "timestamp": now,
            "exp": now + 300
        ]

        guard let token = try? JWTSigner.sign(payload: payload, secret: secret) else {
            return [:]
        }
        return ["X-Sign": token]
    }
}
