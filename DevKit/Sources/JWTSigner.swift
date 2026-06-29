import Foundation
import CryptoKit

/// JWT HS256 signer. Dev-only — не включать в распространяемый SDK.
enum JWTSigner {

    /// Генерирует JWT HS256 с переданным payload.
    /// - Parameters:
    ///   - payload: Поля payload (сериализуются в JSON).
    ///   - secret: Секрет подписи (UTF-8).
    /// - Returns: Строка вида `header.payload.signature`.
    static func sign(payload: [String: Any], secret: String) throws -> String {
        let header: [String: Any] = ["alg": "HS256", "typ": "JWT"]

        let headerData = try JSONSerialization.data(withJSONObject: header, options: [.sortedKeys])
        let payloadData = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])

        let headerEncoded = base64url(headerData)
        let payloadEncoded = base64url(payloadData)

        let signingInput = "\(headerEncoded).\(payloadEncoded)"
        guard let signingData = signingInput.data(using: .utf8) else {
            throw JWTError.encodingFailed
        }

        let keyData = Data(secret.utf8)
        let symmetricKey = SymmetricKey(data: keyData)
        let mac = HMAC<SHA256>.authenticationCode(for: signingData, using: symmetricKey)
        let signature = base64url(Data(mac))

        return "\(signingInput).\(signature)"
    }

    // MARK: - Private

    private static func base64url(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    enum JWTError: Error {
        case encodingFailed
    }
}
