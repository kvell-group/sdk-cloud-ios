//
//  CardPaymentService.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import Foundation

final class CardPaymentService {

    enum Outcome {
        case success(transaction: PaymentTransactionResponse?, message: String?)
        case requires3ds(ThreeDsData)
        case declined(message: String, code: String?)
    }

    private let configuration: PaymentConfiguration

    private lazy var network = KvellApi(
        publicId: configuration.publicId,
        apiUrl: configuration.apiUrl,
        dispatcher: configuration.networkDispatcher,
        apiSecret: configuration.apiSecret
    )

    init(configuration: PaymentConfiguration) {
        self.configuration = configuration
    }

    func pay(cryptogram: String, email: String?, completion: @escaping (Outcome) -> Void) {
        network.charge(
            amount: configuration.paymentData.amount,
            currency: configuration.paymentData.currency,
            ipAddress: "127.0.0.1",
            cardCryptogramPacket: cryptogram,
            invoiceId: configuration.paymentData.invoiceId,
            description: configuration.paymentData.description,
            accountId: configuration.paymentData.accountId,
            email: email ?? configuration.paymentData.email,
            jsonData: configuration.paymentData.jsonData
        ) { [weak self] _, response in
            guard let self else { return }
            completion(self.outcome(from: response))
        }
    }

    func complete3ds(transactionId: String, md: String, paRes: String, completion: @escaping (Outcome) -> Void) {
        let resolvedTransactionId = Int(md) ?? Int(transactionId) ?? 0
        network.post3ds(transactionId: resolvedTransactionId, paRes: paRes) { [weak self] response in
            guard let self else { return }
            completion(self.outcomeAfter3ds(from: response))
        }
    }

    static func declinedOutcome(rawMessage: String?) -> Outcome {
        .declined(message: resolveMessage(rawMessage), code: nil)
    }

    private func outcome(from response: CardsResponse?) -> Outcome {
        guard let model = response?.Model else {
            return .declined(message: Self.resolveMessage(response?.Message), code: nil)
        }

        if let acsUrl = model.AcsUrl, !acsUrl.isEmpty {
            let threeDsData = ThreeDsData(
                transactionId: String(model.TransactionId),
                paReq: model.PaReq ?? "",
                acsUrl: acsUrl,
                threeDSCallbackId: model.ThreeDsCallbackId
            )
            return .requires3ds(threeDsData)
        }

        if response?.Success == true || Self.isSuccessStatus(model.Status) {
            let transaction = PaymentTransactionResponse(
                transactionId: Int64(model.TransactionId),
                paymentMethod: "Card",
                puid: nil,
                status: model.Status,
                code: model.ReasonCode.map(String.init)
            )
            return .success(transaction: transaction, message: model.CardHolderMessage)
        }

        let message = Self.resolveMessage(model.CardHolderMessage ?? response?.Message)
        let code = model.ReasonCode.map(String.init)
        return .declined(message: message, code: code)
    }

    private func outcomeAfter3ds(from response: CardsResponse?) -> Outcome {
        if response?.Success == true {
            let model = response?.Model
            let transaction = model.map {
                PaymentTransactionResponse(
                    transactionId: Int64($0.TransactionId),
                    paymentMethod: "Card",
                    puid: nil,
                    status: $0.Status,
                    code: $0.ReasonCode.map(String.init)
                )
            }
            return .success(transaction: transaction, message: model?.CardHolderMessage)
        }

        let message = Self.resolveMessage(response?.Model?.CardHolderMessage ?? response?.Message)
        let code = response?.Model?.ReasonCode.map(String.init)
        return .declined(message: message, code: code)
    }

    private static func isSuccessStatus(_ status: String?) -> Bool {
        guard let status = status?.lowercased() else { return false }
        return status == "completed" || status == "authorized"
    }

    private static func resolveMessage(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else {
            return ApiError.getFullErrorDescriptionIntentApi(from: nil)
        }
        if Int(raw) != nil {
            return ApiError.getFullErrorDescriptionIntentApi(from: raw)
        }
        if raw.hasPrefix("<") || raw.contains("<html") {
            return ApiError.getFullErrorDescriptionIntentApi(from: nil)
        }
        return raw
    }
}
