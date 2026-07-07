//
//  PaymentOptionsViewModel.swift
//  sdk
//
//  Created by Kvell on 29.07.2025.
//  Copyright © 2025 Kvell. All rights reserved.
//

import UIKit
import Foundation
import KvellNetworking

final class BottomSheetPaymentOptionsViewModel {
    
    enum PaymentIntentError: Error {
        case missingPublicKey
        case intentNotCreated
    }
    
    let configuration: PaymentConfiguration
    
    init(configuration: PaymentConfiguration) {
        self.configuration = configuration
    }
    
    func loadPublicKeyAndCreateIntent(
        completion: @escaping (Result<([PaymentMethod], [String]?, PaymentIntentResponse), Error>) -> Void
    ) {
        KvellApi.getPublicKey(apiUrl: configuration.apiUrl,
                              dispatcher: configuration.networkDispatcher ?? KvellURLSessionNetworkDispatcher.instance) { [weak self] publicKey, _ in
            guard let self else { return }
            guard let pem = publicKey?.Pem, let version = publicKey?.Version else {
                completion(.failure(PaymentIntentError.missingPublicKey))
                return
            }

            configuration.paymentData.pem = pem
            configuration.paymentData.version = version

            guard let cardMethod = try? JSONDecoder().decode(
                PaymentMethod.self,
                from: Data(#"{"type":"Card"}"#.utf8)
            ) else {
                completion(.failure(PaymentIntentError.intentNotCreated))
                return
            }

            let methods = [cardMethod]
            savePaymentLinks(from: methods)
            configuration.paymentData.cachedMethods = methods

            completion(.success((methods, ["Card"], BottomSheetPaymentOptionsViewModel.makePseudoIntent())))
        }
    }

    private static func makePseudoIntent() -> PaymentIntentResponse {
        PaymentIntentResponse(
            id: nil,
            transactions: nil,
            transaction: nil,
            paymentSchema: nil,
            secret: nil,
            status: nil,
            threeDsCallbackId: nil,
            acsUrl: nil,
            paReq: nil,
            amount: nil,
            currency: nil,
            culture: nil,
            createdDate: nil,
            updatedDate: nil,
            description: nil,
            tokenize: nil,
            externalId: nil,
            paymentUrl: nil,
            receiptEmail: nil,
            payerServiceFee: nil,
            offerLink: nil,
            successRedirectUrl: nil,
            failRedirectUrl: nil,
            paymentMethods: nil,
            restrictedPaymentMethods: nil,
            paymentMethodSequence: ["Card"],
            items: nil,
            terminalInfo: nil,
            userInfo: nil,
            tag: nil,
            requireEmail: nil,
            publicTerminalId: nil,
            authCode: nil,
            authDate: nil,
            reference: nil,
            affiliationId: nil,
            lastFour: nil,
            isCard: nil,
            installmentData: nil,
            escrow: nil,
            retryPayment: nil,
            autoClose: nil,
            cryptogramMode: nil
        )
    }
    
    private func savePaymentLinks(from methods: [PaymentMethod]) {
        for method in methods {
            guard let typeString = method.type,
                  let type = PaymentMethodType(rawValue: typeString) else {
                continue
            }

            switch type {
            case .card:
                print("Card: link не сохраняем")
            }
        }
    }
}
