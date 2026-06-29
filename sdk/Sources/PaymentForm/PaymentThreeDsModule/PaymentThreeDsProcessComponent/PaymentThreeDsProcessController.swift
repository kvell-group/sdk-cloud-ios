//
//  PaymentThreeDsProcessController.swift
//  sdk
//
//  Created by Kvell on 16.09.2025.
//  Copyright © 2025 Kvell. All rights reserved.
//

import UIKit
import WebKit
import PassKit

final class PaymentThreeDsProcessController: BaseViewController {

    typealias PaymentCallbackIntentApi = (_ status: Bool, _ canceled: Bool, _ transaction: PaymentIntentResponse?, _ errorMessage: String?) -> ()

    // MARK: UI
    private let threeDsFormView = UIView()
    private let threeDsContainerView = UIView()
    private let threeDsCloseButton = CPButton()

    // MARK: 3DS engine & networking
    private lazy var threeDsProcessor = ThreeDsProcessor()
    private var threeDsCallbackId: String = ""
    private var threeDsCompletionIntentApi: PaymentCallbackIntentApi?
    private var paymentResponse: PaymentIntentResponse?
    private var threeDsTransactionId: Int = 0

    lazy var network: KvellApi = KvellApi(publicId: configuration.publicId,
                                          apiUrl: configuration.apiUrl,
                                          dispatcher: configuration.networkDispatcher,
                                          apiSecret: configuration.apiSecret)

    // MARK: Config
    private let configuration: PaymentConfiguration

    // MARK: Init
    init(configuration: PaymentConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: .mainSdk)
    }
    
    @MainActor required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupThreeDsUI()
        configureThreeDsCloseButton()
    }
}

// MARK: - UI setup

private extension PaymentThreeDsProcessController {
    func setupThreeDsUI() {
        view.backgroundColor = .clear

        threeDsFormView.translatesAutoresizingMaskIntoConstraints = false
        threeDsFormView.backgroundColor = .white
        threeDsFormView.isHidden = true
        threeDsFormView.alpha = 0
        view.addSubview(threeDsFormView)

        threeDsCloseButton.translatesAutoresizingMaskIntoConstraints = false
                threeDsCloseButton.setIcon(UIImage(systemName: "xmark"))
                threeDsCloseButton.setPadding(.init(top: 8, leading: 8, bottom: 8, trailing: 8))
        threeDsFormView.addSubview(threeDsCloseButton)

        threeDsContainerView.translatesAutoresizingMaskIntoConstraints = false
        threeDsContainerView.backgroundColor = .clear
        threeDsFormView.addSubview(threeDsContainerView)

        NSLayoutConstraint.activate([
            threeDsFormView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            threeDsFormView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            threeDsFormView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            threeDsFormView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            threeDsCloseButton.topAnchor.constraint(equalTo: threeDsFormView.topAnchor, constant: 8),
            threeDsCloseButton.trailingAnchor.constraint(equalTo: threeDsFormView.trailingAnchor, constant: -8),
            threeDsCloseButton.widthAnchor.constraint(equalToConstant: 36),
            threeDsCloseButton.heightAnchor.constraint(equalToConstant: 36),

            threeDsContainerView.topAnchor.constraint(equalTo: threeDsCloseButton.bottomAnchor, constant: 4),
            threeDsContainerView.leadingAnchor.constraint(equalTo: threeDsFormView.leadingAnchor),
            threeDsContainerView.trailingAnchor.constraint(equalTo: threeDsFormView.trailingAnchor),
            threeDsContainerView.bottomAnchor.constraint(equalTo: threeDsFormView.bottomAnchor)
        ])
    }

    func configureThreeDsCloseButton() {
        threeDsCloseButton.onAction = { [weak self] in
            guard let self else { return }
            self.threeDsCompletionIntentApi?(false, true, nil, nil)
            self.closeThreeDs { [weak self] in
                self?.threeDsCompletionIntentApi?(false, true, nil, nil)
            }
        }
    }

    func showThreeDsForm(animated: Bool = true) {
        threeDsFormView.isHidden = false
        guard animated else { threeDsFormView.alpha = 1; return }
        UIView.animate(withDuration: 0.25) { self.threeDsFormView.alpha = 1 }
    }

    func closeThreeDs(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, animations: {
            self.threeDsFormView.alpha = 0
        }, completion: { _ in
            self.threeDsFormView.isHidden = true
            self.threeDsContainerView.subviews.forEach { $0.removeFromSuperview() }
            completion?()
        })
    }
}

// MARK: - Classic charge API

extension PaymentThreeDsProcessController {

    func cardPay(cardCryptogramPacket: String, email: String?, completion: PaymentCallbackIntentApi?) {
        network.charge(
            amount: configuration.paymentData.amount,
            currency: configuration.paymentData.currency,
            ipAddress: "127.0.0.1",
            cardCryptogramPacket: cardCryptogramPacket,
            invoiceId: configuration.paymentData.invoiceId,
            description: configuration.paymentData.description,
            accountId: configuration.paymentData.accountId,
            email: email ?? configuration.paymentData.email,
            jsonData: configuration.paymentData.jsonData
        ) { [weak self] _, response in
            guard let self else { return }
            guard let model = response?.Model else {
                completion?(false, false, nil, response?.Message)
                return
            }

            if let acsUrl = model.AcsUrl, !acsUrl.isEmpty {
                self.show3ds(model: model, acsUrl: acsUrl, completion: completion)
                return
            }

            if response?.Success == true || Self.isSuccessStatus(model.Status) {
                completion?(true, false, Self.makePseudoIntent(from: model), nil)
            } else {
                let message = model.CardHolderMessage ?? response?.Message
                completion?(false, false, Self.makePseudoIntent(from: model), message)
            }
        }
    }

    func show3ds(model: CardsResponseModel, acsUrl: String, completion: PaymentCallbackIntentApi?) {
        self.threeDsCompletionIntentApi = nil
        self.threeDsTransactionId = model.TransactionId
        self.threeDsCallbackId = model.ThreeDsCallbackId ?? ""
        self.paymentResponse = Self.makePseudoIntent(from: model)

        let threeDsData = ThreeDsData(
            transactionId: String(model.TransactionId),
            paReq: model.PaReq ?? "",
            acsUrl: acsUrl,
            threeDSCallbackId: model.ThreeDsCallbackId
        )

        threeDsProcessor.make3DSPayment(with: threeDsData, delegate: self)
        self.threeDsCompletionIntentApi = completion
    }
}

// MARK: - CardsResponse → PaymentIntentResponse

private extension PaymentThreeDsProcessController {

    static func isSuccessStatus(_ status: String?) -> Bool {
        guard let status = status?.lowercased() else { return false }
        return status == "completed" || status == "authorized"
    }

    static func makePseudoIntent(from model: CardsResponseModel) -> PaymentIntentResponse {
        let transaction = PaymentTransactionResponse(
            transactionId: Int64(model.TransactionId),
            paymentMethod: "Card",
            puid: nil,
            status: model.Status,
            code: model.ReasonCode.map(String.init)
        )
        return PaymentIntentResponse(
            id: nil,
            transactions: nil,
            transaction: transaction,
            paymentSchema: nil,
            secret: nil,
            status: model.Status,
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
            paymentMethodSequence: nil,
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
}

// MARK: - ThreeDsDelegate

extension PaymentThreeDsProcessController: ThreeDsDelegate {
    public func willPresentWebView(_ webView: WKWebView) {
        threeDsContainerView.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: threeDsContainerView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: threeDsContainerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: threeDsContainerView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: threeDsContainerView.bottomAnchor)
        ])
        showThreeDsForm(animated: true)
        AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/3ds", methodChosen: "Card", cardFieldsCount: 0, eventType: "Open")
    }

    public func onAuthorizationCompleted(with md: String, paRes: String) {
        let transactionId = Int(md) ?? threeDsTransactionId
        let api = KvellApi(publicId: configuration.publicId,
                           apiUrl: configuration.apiUrl,
                           dispatcher: configuration.networkDispatcher,
                           apiSecret: configuration.apiSecret)
        closeThreeDs { [weak self] in
            guard let self else { return }
            api.post3ds(transactionId: transactionId, paRes: paRes) { [weak self] response in
                guard let self else { return }
                if response?.Success == true {
                    let intent = response?.Model.map(Self.makePseudoIntent) ?? self.paymentResponse
                    self.threeDsCompletionIntentApi?(true, false, intent, nil)
                } else {
                    let intent = response?.Model.map(Self.makePseudoIntent) ?? self.paymentResponse
                    let message = response?.Model?.CardHolderMessage ?? response?.Message
                    self.threeDsCompletionIntentApi?(false, false, intent, message)
                }
            }
        }
    }

    public func onAuthorizationFailed(with html: String) {
        closeThreeDs { [weak self] in
            guard let self else { return }
            self.threeDsCompletionIntentApi?(false, false, self.paymentResponse, html)
        }
    }
}
