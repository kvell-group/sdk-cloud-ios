//
//  ThreeDsPageViewController.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit
import WebKit

final class ThreeDsPageViewController: BaseViewController {

    var onCompleted: ((_ md: String, _ paRes: String) -> Void)?
    var onFailed: ((String) -> Void)?

    private let configuration: PaymentConfiguration
    private let intent: PaymentIntentResponse?

    private let scaffold = PaymentPageScaffoldView()
    private let webViewContainer = UIView()
    private var webViewHeightConstraint: NSLayoutConstraint!

    init(configuration: PaymentConfiguration, intent: PaymentIntentResponse?) {
        self.configuration = configuration
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    private func buildContent() -> UIView {
        webViewContainer.translatesAutoresizingMaskIntoConstraints = false
        webViewHeightConstraint = webViewContainer.heightAnchor.constraint(equalToConstant: 360)
        webViewHeightConstraint.isActive = true

        let stack = UIStackView(arrangedSubviews: [makeWarningNotification(), webViewContainer])
        stack.axis = .vertical
        stack.spacing = 16
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        return stack
    }

    private func makeWarningNotification() -> UIView {
        let container = UIView()
        container.backgroundColor = KvellDesign.Color.surfaceWarning
        container.layer.borderWidth = 1
        container.layer.borderColor = KvellDesign.Color.borderNormal.cgColor
        container.layer.cornerRadius = KvellDesign.Radius.xl

        let icon = UIImageView(image: UIImage.named("kv_warning"))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20)
        ])

        let label = UILabel()
        label.numberOfLines = 0
        label.setStyledText(
            "Не покидайте окно проверки платежа — отмена 3D Secure приведёт к отклонению платежа",
            style: KvellDesign.Font.bodySMedium,
            color: KvellDesign.Color.textPrimary
        )

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
        return container
    }
}

extension ThreeDsPageViewController: ThreeDsDelegate {

    func willPresentWebView(_ webView: WKWebView) {
        webViewContainer.subviews.forEach { $0.removeFromSuperview() }
        webViewContainer.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(webView.pinToSuperviewEdges())
    }

    func onAuthorizationCompleted(with md: String, paRes: String) {
        onCompleted?(md, paRes)
    }

    func onAuthorizationFailed(with html: String) {
        onFailed?(html)
    }
}
