// MockNetworkDispatcher.swift
// KvellDevKit — dev-only, не распространяется.
//
// Эмулирует сетевые ответы для демонстрации флоу оплаты картой без реального бэка.
// Все запросы перехватываются через DI (KvellNetworkDispatcher), URLProtocol не нужен.

import Foundation
import KvellNetworking

// MARK: - MockNetworkDispatcher

public final class MockNetworkDispatcher: KvellNetworkDispatcher {

    // MARK: - Scenario

    public enum Scenario {
        case success
        case requires3DS
        case decline
    }

    // MARK: - Properties

    public var scenario: Scenario

    public init(scenario: Scenario = .success) {
        self.scenario = scenario
    }

    // MARK: - KvellNetworkDispatcher

    public func dispatch(request: KvellRequest,
                         onSuccess: @escaping (Data) -> Void,
                         onError: @escaping (Error) -> Void,
                         onRedirect: ((URLRequest) -> Bool)?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            do {
                let data = try self.responseData(for: request)
                onSuccess(data)
            } catch {
                onError(error)
            }
        }
    }

    public func dispatchWithStatusCode(request: KvellRequest,
                                       onSuccess: @escaping (Int, Data) -> Void,
                                       onError: @escaping (Error, Int) -> Void,
                                       onRedirect: ((URLRequest) -> Bool)?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            do {
                let (code, data) = try self.responseDataWithStatusCode(for: request)
                onSuccess(code, data)
            } catch {
                onError(error, 0)
            }
        }
    }

    // MARK: - Routing

    private func responseData(for request: KvellRequest) throws -> Data {
        let (_, data) = try responseDataWithStatusCode(for: request)
        return data
    }

    private func responseDataWithStatusCode(for request: KvellRequest) throws -> (Int, Data) {
        let path = request.path

        if path.contains("payments/publickey") {
            return (200, try encode(MockFixtures.publicKey))
        }

        if path.contains("payments/cards/post3ds") {
            return (200, MockFixtures.post3dsSuccess)
        }

        if path.contains("payments/cards/charge") {
            return (200, chargeResponse(scenario: scenario))
        }

        if path.contains("bins/info") || path.contains("bininfo") {
            return (200, try encode(MockFixtures.binInfo))
        }

        // Неизвестный путь — пустой JSON 200
        print("[MockNetworkDispatcher] Unknown path: \(path) — returning empty JSON 200")
        return (200, Data("{}".utf8))
    }

    private func chargeResponse(scenario: Scenario) -> Data {
        switch scenario {
        case .success:
            return MockFixtures.chargeSuccess
        case .requires3DS:
            return MockFixtures.chargeRequires3DS
        case .decline:
            return MockFixtures.chargeDecline
        }
    }

    private func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(value)
    }
}

// MARK: - Mock Fixtures

private enum MockFixtures {

    // MARK: Public Key
    // Реальный публичный ключ прод-гейтвея (эндпоинт /crypto/public-key/).
    // Получен 2026-06-21. Используется чтобы RSAUtils / Card.makeCardCryptogramPacket
    // реально шифровал данные карты (проверка крипто-пайпа без бэка).
    static let publicKey = PublicKeyFixture(
        pem: "-----BEGIN PUBLIC KEY-----MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAz6EFV/urgl8XeHSV22WIP3wHv/cMt4jHNglFxTics0EEgg/e+dmUFe2CgnukdWmEeixR89jtnf/yTCSiQ4L9yH/SbuP4jNNaOkx+U9Hpp4IwcXNQ369cd5HSPhE46e7PzagEl8G+QvhsNb4M6+usBVy5civjd/aN401AQbwYUIFu0NIz+qzVkli+7SkBgbnPwho30CAz7UmucR/b3X1eGWu/Mj3RTBJ8i7nzQh3I8/WM6txI0mT1yLpi9j3EZDSr+EzMow49QcOy05xAvLYO99sSCF2nMwDR4lbQSFn2S4c79k0odvHYqh5EACmef+gLZCLc/53L3HEyeEpXK1eCIQIDAQAB-----END PUBLIC KEY-----",
        version: 1
    )

    // MARK: Charge — immediate success (CardsResponse, PascalCase, HTTP 200)
    static let chargeSuccess = Data(#"""
    {"Success": true, "Model": {"TransactionId": 123456789, "Status": "Completed"}}
    """#.utf8)

    // MARK: Charge — 3DS required (CardsResponse, HTTP 200)
    // AcsUrl — нерезолвящийся placeholder: SDK POST-ит на него реальным URLSession (мимо
    // dispatcher-а), DNS-ошибка завершает сценарий через onAuthorizationFailed
    // (экран ошибки вместо WebView с реальной ACS-страницей).
    static let chargeRequires3DS = Data(#"""
    {"Success": false, "Model": {"TransactionId": 123456789, "AcsUrl": "https://acs.pay-pulse.example/", "PaReq": "mock-pa-req", "ThreeDsCallbackId": "mock-3ds-callback-id"}}
    """#.utf8)

    // MARK: Charge — decline (CardsResponse, HTTP 200)
    static let chargeDecline = Data(#"""
    {"Success": false, "Message": "Отказ банка", "Model": {"TransactionId": 123456789, "ReasonCode": 5051, "CardHolderMessage": "Недостаточно средств"}}
    """#.utf8)

    // MARK: Post3DS — success (CardsResponse, HTTP 200)
    static let post3dsSuccess = Data(#"""
    {"Success": true, "Model": {"TransactionId": 123456789, "Status": "Completed"}}
    """#.utf8)

    // MARK: Bin Info
    static let binInfo = BinInfoFixture(
        success: true,
        model: BankInfoFixture(
            logoURL: nil,
            convertedAmount: nil,
            currency: "RUB",
            hideCvvInput: false,
            isCardAllowed: true,
            cardType: "Visa",
            bankName: "Mock Bank",
            countryCode: 643
        )
    )
}

// MARK: - Fixture Codable Types

private struct PublicKeyFixture: Encodable {
    let pem: String
    let version: Int
}

// BinInfo response: {"Success": true, "Model": {...}}  (UpperCamelCase CodingKeys)
private struct BinInfoFixture: Encodable {
    let success: Bool?
    let model: BankInfoFixture?

    enum CodingKeys: String, CodingKey {
        case success = "Success"
        case model = "Model"
    }
}

private struct BankInfoFixture: Encodable {
    let logoURL: String?
    let convertedAmount: String?
    let currency: String?
    let hideCvvInput: Bool?
    let isCardAllowed: Bool?
    let cardType: String?
    let bankName: String?
    let countryCode: Int?
}
