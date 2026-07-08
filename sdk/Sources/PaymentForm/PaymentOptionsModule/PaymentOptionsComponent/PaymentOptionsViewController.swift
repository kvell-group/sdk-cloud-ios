//
//  PaymentOptionsViewController.swift
//  sdk
//
//  Created by Kvell on 29.07.2025.
//  Copyright © 2025 Kvell. All rights reserved.
//

import UIKit
import Foundation
import KvellNetworking

public final class PaymentOptionsViewController: BaseViewController {

    enum ResolvedPaymentMethodKind {
        case regular
    }

    struct ResolvedPaymentMethod {
        let method: PaymentMethod
        let displayType: PaymentMethodType
        let kind: ResolvedPaymentMethodKind
    }

    private let loaderView = LoaderView()
    private let configuration: PaymentConfiguration
    private let viewModel: BottomSheetPaymentOptionsViewModel
    private let skipLoader: Bool
    private var hostNavigationController: UINavigationController?
    private var flowContainer: PaymentFlowContainerViewController?
    private var currentIntent: PaymentIntentResponse?

    private lazy var cardPaymentService = CardPaymentService(configuration: configuration)
    private lazy var threeDsProcessor = ThreeDsProcessor()

    init(configuration: PaymentConfiguration, skipLoader: Bool = false) {
        self.configuration = configuration
        self.skipLoader = skipLoader
        self.viewModel = BottomSheetPaymentOptionsViewModel(configuration: configuration)
        super.init(nibName: nil, bundle: .mainSdk)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Present

    @discardableResult
    public class func present(
        with configuration: PaymentConfiguration,
        from presentingViewController: UIViewController,
        skipLoader: Bool = false,
        completion: (() -> ())? = nil
    ) -> PaymentOptionsViewController {
        let controller = PaymentOptionsViewController(configuration: configuration, skipLoader: skipLoader)
        presentingViewController.present(controller, animated: true) {
            completion?()
        }

        if !configuration.paymentData.analyticsSessionStarted {
            AnalyticsService.shared.startSession()
            AnalyticsService.shared.sendScreenOpenedEvent(
                configuration: configuration,
                screenName: "PreStart",
                cardFieldsCount: 0,
                eventType: "Open"
            )
            configuration.paymentData.analyticsSessionStarted = true
        }

        return controller
    }

    public override func loadView() {
        super.loadView()
        if !skipLoader {
            view.addSubview(loaderView)
            loaderView.frame = view.bounds
            loaderView.fullConstraint()
            loaderView.isHidden = true
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        if skipLoader,
           let methods = configuration.paymentData.cachedMethods,
           !methods.isEmpty {
            presentOptions(methods: methods, paymentMethodSequence: nil, intent: nil)
        } else {
            showLoading()
        }

        LoggerService.shared.startLogging(publicId: configuration.publicId)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if configuration.singlePaymentMode == nil {
            configuration.paymentUIDelegate.paymentFormWillDisplay()
            configuration.paymentUIDelegate.paymentFormDidDisplay()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if configuration.singlePaymentMode == nil {
            configuration.paymentUIDelegate.paymentFormWillHide()
        }
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if configuration.singlePaymentMode == nil {
            configuration.paymentUIDelegate.paymentFormDidHide()
        }
    }

    // MARK: - Loader

    private func showLoading() {
        loaderView(isOn: true) {
            self.viewModel.loadPublicKeyAndCreateIntent { [weak self] result in
                DispatchQueue.main.async {
                    guard let self else { return }

                    switch result {
                    case .success(let (methods, paymentMethodSequence, intent)):
                        self.loaderView(isOn: false) {
                            self.presentOptions(
                                methods: methods,
                                paymentMethodSequence: paymentMethodSequence,
                                intent: intent
                            )
                        }

                    case .failure:
                        self.loaderView(isOn: false) {
                            AnalyticsService.shared.sendScreenOpenedEvent(
                                configuration: self.configuration,
                                screenName: "/static-error",
                                cardFieldsCount: 0,
                                eventType: "Open"
                            )
                            self.showAlert(title: .errorWord, message: .errorConfiguration) {
                                self.dismiss(animated: true) {
                                    self.configuration.paymentDelegate.paymentClosed()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func resolveMethods(
        from methods: [PaymentMethod],
        paymentMethodSequence: [String]?
    ) -> [ResolvedPaymentMethod] {
        var resolved: [ResolvedPaymentMethod] = []
        var usedTypes = Set<String>()

        for method in methods {
            guard let typeString = method.type,
                  let displayType = PaymentMethodType(rawValue: typeString),
                  !usedTypes.contains(typeString) else { continue }

            resolved.append(ResolvedPaymentMethod(method: method, displayType: displayType, kind: .regular))
            usedTypes.insert(typeString)
        }

        print("Итоговое количество кнопок: \(resolved.count)")
        return resolved
    }

    private func displayMethodTypes(resolvedMethods: [ResolvedPaymentMethod], serverSequence: [String]?) -> [PaymentMethodType] {
        let types = resolvedMethods.map { $0.displayType }

        var sequence = (serverSequence ?? []).compactMap { PaymentMethodType(rawValue: $0) }
        for type in configuration.paymentMethodSequence where !sequence.contains(type) {
            sequence.append(type)
        }

        guard !sequence.isEmpty else { return types }

        return types.enumerated().sorted { lhs, rhs in
            let lhsIndex = sequence.firstIndex(of: lhs.element) ?? sequence.count + lhs.offset
            let rhsIndex = sequence.firstIndex(of: rhs.element) ?? sequence.count + rhs.offset
            return lhsIndex < rhsIndex
        }.map { $0.element }
    }

    private func presentOptions(
        methods: [PaymentMethod],
        paymentMethodSequence: [String]?,
        intent: PaymentIntentResponse?
    ) {
        currentIntent = intent

        let resolvedMethods = resolveMethods(
            from: methods,
            paymentMethodSequence: paymentMethodSequence
        )

        if let singleMode = configuration.singlePaymentMode {
            guard let resolved = resolvedMethods.first(where: { $0.displayType.rawValue == singleMode.rawValue }) else {
                if configuration.showResultScreenForSinglePaymentMode {
                    showAlert(title: .errorWord, message: .errorConfiguration) {
                        self.dismiss(animated: true) {
                            self.configuration.paymentDelegate.paymentClosed()
                        }
                    }
                } else {
                    self.dismiss(animated: true) { [weak self] in
                        self?.configuration.paymentDelegate.paymentClosed()
                    }
                }
                return
            }

            launchResolvedMethod(resolved, intent: intent, showBackButton: false)
            return
        }

        let displayTypes = displayMethodTypes(resolvedMethods: resolvedMethods, serverSequence: paymentMethodSequence)

        if displayTypes == [.card], let single = resolvedMethods.first(where: { $0.displayType == .card }) {
            launchResolvedMethod(single, intent: intent, showBackButton: false)
        } else {
            showMethodsPage(resolvedMethods: resolvedMethods, displayTypes: displayTypes, intent: intent)
        }
    }

    private func launchResolvedMethod(_ resolved: ResolvedPaymentMethod, intent: PaymentIntentResponse?, showBackButton: Bool) {
        guard resolved.displayType == .card else { return }
        let page = makeCardPage(resolved: resolved, intent: intent, showBackButton: showBackButton)
        _ = embedNavigation(root: page)
    }

    private func showMethodsPage(resolvedMethods: [ResolvedPaymentMethod], displayTypes: [PaymentMethodType], intent: PaymentIntentResponse?) {
        let page = PaymentMethodsPageViewController(
            configuration: configuration,
            displayTypes: displayTypes,
            intent: intent
        )

        page.onSelectCard = { [weak self] in
            guard let self, let cardResolved = resolvedMethods.first(where: { $0.displayType == .card }) else { return }
            let cardPage = self.makeCardPage(resolved: cardResolved, intent: intent, showBackButton: true)
            self.hostNavigationController?.pushViewController(cardPage, animated: true)
        }

        _ = embedNavigation(root: page)

        if let intent {
            let displayedMethods = displayTypes.map { $0.rawValue }
            configuration.paymentData.methodsAvailable = displayedMethods

            AnalyticsService.shared.sendScreenOpenedEvent(
                configuration: configuration,
                screenName: "Start",
                methodsAvailable: displayedMethods,
                cardFieldsCount: 0,
                eventType: "Open"
            )

            AnalyticsService.shared.sendPaymentMethodsStartSessionEvent(
                configuration: configuration,
                intent: intent,
                methodsAvailable: displayedMethods,
                displayedMethods: displayedMethods
            )
        }
    }

    private func makeCardPage(resolved: ResolvedPaymentMethod, intent: PaymentIntentResponse?, showBackButton: Bool) -> CardPaymentPageViewController {
        let page = CardPaymentPageViewController(
            configuration: configuration,
            intent: intent,
            showBackButton: showBackButton
        )
        page.onBack = { [weak self] in self?.hostNavigationController?.popViewController(animated: true) }
        page.onPatch = { [weak self] email, tokenize in self?.patch(email: email, tokenize: tokenize) }
        page.onPay = { [weak self] cryptogram, email in self?.startCardPayment(cryptogram: cryptogram, email: email) }
        return page
    }

    private func embedNavigation(root: UIViewController) -> UINavigationController {
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }

        let container = PaymentFlowContainerViewController(rootViewController: root, sessionDeadline: resolvedSessionDeadline())
        container.onClose = { [weak self] in self?.handleClose(screenName: self?.currentScreenName() ?? "/methods") }

        addChild(container)
        container.view.frame = view.bounds
        container.view.alpha = 0
        container.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container.view)
        NSLayoutConstraint.activate([
            container.view.topAnchor.constraint(equalTo: view.topAnchor),
            container.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        container.didMove(toParent: self)

        UIView.animate(withDuration: 0.35) {
            container.view.alpha = 1
        }

        flowContainer = container
        hostNavigationController = container.navigation
        return container.navigation
    }

    private func resolvedSessionDeadline() -> Date? {
        guard let seconds = configuration.paymentData.sessionLifetimeSeconds else { return nil }
        if let existing = configuration.paymentData.sessionDeadline { return existing }
        let deadline = Date().addingTimeInterval(TimeInterval(seconds))
        configuration.paymentData.sessionDeadline = deadline
        return deadline
    }

    private func currentScreenName() -> String {
        switch hostNavigationController?.topViewController {
        case is CardPaymentPageViewController: return "/methods/card-edit"
        case is PaymentMethodsPageViewController: return "/methods"
        case is ThreeDsPageViewController: return "/3ds"
        default: return "/methods"
        }
    }

    private func handleClose(screenName: String) {
        closeFlow(screenName: screenName, elementLabel: "Close", actionType: "Close")
    }

    private func closeFlow(screenName: String, elementLabel: String, actionType: String) {
        AnalyticsService.shared.sendActionClickEvent(
            configuration: configuration,
            elementLabel: elementLabel,
            elementType: "Button",
            actionType: actionType,
            screenName: screenName
        )
        dismiss(animated: true) { [weak self] in
            self?.configuration.paymentDelegate.paymentClosed()
        }
    }

}

// MARK: - Card payment orchestration

private extension PaymentOptionsViewController {

    func startCardPayment(cryptogram: String, email: String?) {
        guard let hostNavigationController else { return }

        let pendingPage = PaymentStatusPageViewController(configuration: configuration, intent: currentIntent, state: .pending)
        hostNavigationController.pushViewController(pendingPage, animated: true)
        flowContainer?.setCloseEnabled(false)

        cardPaymentService.pay(cryptogram: cryptogram, email: email) { [weak self] outcome in
            self?.handleCardPaymentOutcome(outcome)
        }
    }

    func handleCardPaymentOutcome(_ outcome: CardPaymentService.Outcome) {
        switch outcome {
        case .success(let transaction, let message):
            finishCardPayment(transaction: transaction, message: message)

        case .requires3ds(let data):
            presentThreeDs(data: data)

        case .declined(let message, let code):
            declineCardPayment(message: message, code: code)
        }
    }

    func presentThreeDs(data: ThreeDsData) {
        guard let hostNavigationController else { return }

        let threeDsPage = ThreeDsPageViewController(configuration: configuration, intent: currentIntent)
        threeDsPage.onCompleted = { [weak self] md, paRes in
            guard let self else { return }
            self.hostNavigationController?.popViewController(animated: true)
            self.flowContainer?.setCloseEnabled(false)
            self.cardPaymentService.complete3ds(transactionId: data.transactionId, md: md, paRes: paRes) { [weak self] outcome in
                self?.handleCardPaymentOutcome(outcome)
            }
        }
        threeDsPage.onFailed = { [weak self] html in
            guard let self else { return }
            if case .declined(let message, let code) = CardPaymentService.declinedOutcome(rawMessage: html) {
                self.declineCardPayment(message: message, code: code)
            }
        }

        flowContainer?.setCloseEnabled(true)
        hostNavigationController.pushViewController(threeDsPage, animated: true)
        threeDsProcessor.make3DSPayment(with: data, delegate: threeDsPage)

        AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/3ds", methodChosen: "Card", cardFieldsCount: 0, eventType: "Open")
    }

    func finishCardPayment(transaction: PaymentTransactionResponse?, message: String?) {
        if configuration.singlePaymentMode != nil, !configuration.showResultScreenForSinglePaymentMode {
            dismiss(animated: true) { [weak self] in
                self?.configuration.paymentDelegate.paymentFinished(transaction)
                self?.configuration.paymentDelegate.paymentClosed()
            }
            return
        }

        guard let hostNavigationController else { return }

        let title = message == .orderAlreadyBeenPaid ? .orderAlreadyBeenPaid : "Оплата прошла успешно"
        let successPage = PaymentStatusPageViewController(
            configuration: configuration,
            intent: currentIntent,
            state: .success(title: title, buttonTitle: "Вернуться в магазин")
        )
        successPage.onPrimaryTap = { [weak self] in
            self?.closeFlow(screenName: "/success", elementLabel: "ReturnToShop", actionType: "Click")
        }

        flowContainer?.setCloseEnabled(true)
        hostNavigationController.setViewControllers([successPage], animated: true)

        configuration.paymentDelegate.paymentFinished(transaction)
        AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/success", methodChosen: "Card", cardFieldsCount: 0, eventType: "Open")
    }

    func declineCardPayment(message: String, code: String?) {
        if configuration.singlePaymentMode != nil, !configuration.showResultScreenForSinglePaymentMode {
            dismiss(animated: true) { [weak self] in
                self?.configuration.paymentDelegate.paymentFailed(message)
                self?.configuration.paymentDelegate.paymentClosed()
            }
            return
        }

        guard let hostNavigationController else { return }

        let errorPage = PaymentStatusPageViewController(
            configuration: configuration,
            intent: currentIntent,
            state: .error(message: message, code: code)
        )
        errorPage.onPrimaryTap = { [weak self] in
            guard let self else { return }
            AnalyticsService.shared.sendActionClickEvent(
                configuration: self.configuration,
                elementLabel: "Try again",
                elementType: "Button",
                actionType: "Click",
                screenName: "/fail"
            )
            self.hostNavigationController?.popViewController(animated: true)
        }

        var stack = hostNavigationController.viewControllers
        if let cardIndex = stack.lastIndex(where: { $0 is CardPaymentPageViewController }) {
            stack = Array(stack[0...cardIndex])
        } else if !stack.isEmpty {
            stack = Array(stack.dropLast())
        }
        stack.append(errorPage)

        flowContainer?.setCloseEnabled(true)
        hostNavigationController.setViewControllers(stack, animated: true)

        configuration.paymentDelegate.paymentFailed(message)
        AnalyticsService.shared.sendScreenOpenedEvent(
            configuration: configuration,
            screenName: "/fail",
            methodChosen: "Card",
            cardFieldsCount: 0,
            eventType: "Open",
            errorContext: code
        )
    }
}

private extension PaymentOptionsViewController {

    func loaderView(isOn: Bool, completion: @escaping () -> Void) {
        if isOn {
            loaderView.isHidden = false
            loaderView.startAnimated()
        } else {
            loaderView.endAnimated()
        }

        UIView.animate(withDuration: 0.2) {
            self.loaderView.alpha = isOn ? 1 : 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.loaderView.isHidden = !isOn
            completion()
        }
    }
}

extension PaymentOptionsViewController {

    func patch(email: String?, tokenize: Bool) {
        let patch = PatchBuilder.make { builder in
            if let email = email?.trimmingCharacters(in: .whitespacesAndNewlines),
               !email.isEmpty,
               email.emailIsValid() {
                builder.replace("/receiptEmail", value: email)
                configuration.paymentData.email = email
            } else {
                configuration.paymentData.email = nil
            }

            if case .optional = configuration.paymentData.intentSaveCardState {
                builder.replace("/tokenize", value: tokenize)
                configuration.paymentData.savedTokenize = tokenize
            }
        }

        guard !patch.isEmpty else {
            print("PATCH не выполняем: изменений нет")
            return
        }

        KvellApi.intentPatchById(configuration: configuration, patches: patch,
                                   dispatcher: configuration.networkDispatcher ?? KvellURLSessionNetworkDispatcher.instance) { result in
            print("PATCH выполнен. Email: \(String(describing: result?.receiptEmail)), Tokenize: \(tokenize)")
        }
    }
}
