//
//  PaymentMethodsPageViewController.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

final class PaymentMethodsPageViewController: BaseViewController {

    var onSelectCard: (() -> Void)?

    private let configuration: PaymentConfiguration
    private let displayTypes: [PaymentMethodType]
    private let intent: PaymentIntentResponse?

    private let scaffold = PaymentPageScaffoldView()

    init(
        configuration: PaymentConfiguration,
        displayTypes: [PaymentMethodType],
        intent: PaymentIntentResponse?
    ) {
        self.configuration = configuration
        self.displayTypes = displayTypes
        self.intent = intent
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = KvellDesign.Color.surface

        view.addSubview(scaffold)
        NSLayoutConstraint.activate(scaffold.pinToSuperviewEdges())

        scaffold.orderDetails.configure(with: configuration, intent: intent)
        scaffold.footer.configureDefaultActions()
        scaffold.setContent(buildContent())
    }

    private func buildContent() -> UIView {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        titleLabel.setStyledText("Выберите способ оплаты", style: KvellDesign.Font.bodySBold, color: KvellDesign.Color.textPrimary)

        let methodsStack = UIStackView()
        methodsStack.axis = .vertical
        methodsStack.spacing = 16

        for type in displayTypes {
            let row = PaymentMethodRowView()
            row.configure(
                logo: type.pageLogo,
                logoSize: type.pageLogoSize,
                title: type.pageTitle,
                subtitle: type.pageSubtitle,
                style: type.pageStyle
            )
            row.onTap = { [weak self] in self?.handleTap(type) }
            methodsStack.addArrangedSubview(row)
        }

        let section = UIStackView(arrangedSubviews: [titleLabel, methodsStack])
        section.axis = .vertical
        section.spacing = 24
        section.translatesAutoresizingMaskIntoConstraints = false
        section.isLayoutMarginsRelativeArrangement = true
        section.layoutMargins = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        return section
    }

    private func handleTap(_ type: PaymentMethodType) {
        guard type == .card else { return }

        AnalyticsService.shared.sendActionClickEvent(
            configuration: configuration,
            elementLabel: type.rawValue,
            elementType: "Button",
            actionType: "Click",
            screenName: "/methods"
        )

        onSelectCard?()
    }
}
