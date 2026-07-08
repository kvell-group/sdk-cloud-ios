//
//  PaymentStatusPageViewController.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

final class PaymentStatusPageViewController: BaseViewController {

    enum State {
        case pending
        case success(title: String, buttonTitle: String)
        case error(message: String, code: String?)
    }

    var onPrimaryTap: (() -> Void)?

    private let configuration: PaymentConfiguration
    private let intent: PaymentIntentResponse?
    private let state: State

    private let scaffold = PaymentPageScaffoldView()
    private let spinnerView = RadialSpinnerView()

    init(configuration: PaymentConfiguration, intent: PaymentIntentResponse?, state: State) {
        self.configuration = configuration
        self.intent = intent
        self.state = state
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

        if case .pending = state {
            spinnerView.startAnimating()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if case .pending = state {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if case .pending = state {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }

    private func buildContent() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 140, left: 24, bottom: 140, right: 24)

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        switch state {
        case .pending:
            titleLabel.setStyledText("Ожидание оплаты", style: KvellDesign.Font.bodyLBold, color: KvellDesign.Color.textPrimary)

            let spinnerWrap = wrapCentered(spinnerView, size: CGSize(width: 56, height: 56))
            stack.addArrangedSubview(spinnerWrap)
            stack.addArrangedSubview(titleLabel)
            stack.setCustomSpacing(24, after: spinnerWrap)

        case .success(let title, let buttonTitle):
            let iconView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
            iconView.tintColor = KvellDesign.Color.iconStatusSuccess
            iconView.contentMode = .scaleAspectFit

            titleLabel.setStyledText(title, style: KvellDesign.Font.bodyLBold, color: KvellDesign.Color.textPrimary)

            let button = KvellPrimaryButton()
            button.configure(title: buttonTitle, icon: nil)
            button.addTarget(self, action: #selector(handlePrimaryTap), for: .touchUpInside)

            let iconWrap = wrapCentered(iconView, size: CGSize(width: 72, height: 72))
            let buttonWrap = wrapCentered(button, size: nil)

            stack.addArrangedSubview(iconWrap)
            stack.addArrangedSubview(titleLabel)
            stack.addArrangedSubview(buttonWrap)
            stack.setCustomSpacing(24, after: iconWrap)
            stack.setCustomSpacing(24, after: titleLabel)

        case .error(let message, let code):
            let iconView = UIImageView(image: UIImage.named("kv_warning"))
            iconView.contentMode = .scaleAspectFit

            titleLabel.setStyledText("Оплата не прошла", style: KvellDesign.Font.bodyLBold, color: KvellDesign.Color.textPrimary)

            let messageLabel = UILabel()
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            messageLabel.setStyledText(
                Self.formatErrorText(message: message, code: code),
                style: KvellDesign.Font.captionLRegular,
                color: KvellDesign.Color.textSecondary
            )

            let button = KvellPrimaryButton()
            button.configure(title: "Попробовать снова", icon: nil)
            button.addTarget(self, action: #selector(handlePrimaryTap), for: .touchUpInside)

            let iconWrap = wrapCentered(iconView, size: CGSize(width: 72, height: 72))
            let buttonWrap = wrapCentered(button, size: nil)

            stack.addArrangedSubview(iconWrap)
            stack.addArrangedSubview(titleLabel)
            stack.addArrangedSubview(messageLabel)
            stack.addArrangedSubview(buttonWrap)
            stack.setCustomSpacing(24, after: iconWrap)
            stack.setCustomSpacing(8, after: titleLabel)
            stack.setCustomSpacing(24, after: messageLabel)
        }

        return stack
    }

    private func wrapCentered(_ view: UIView, size: CGSize?) -> UIView {
        let container = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)

        let resolvedSize = size ?? view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            view.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            view.widthAnchor.constraint(equalToConstant: resolvedSize.width),
            view.heightAnchor.constraint(equalToConstant: resolvedSize.height)
        ])
        return container
    }

    private static func formatErrorText(message: String, code: String?) -> String {
        var text = message.contains("#") ? message.components(separatedBy: "#").joined(separator: "\n") : message
        if let code, !code.isEmpty {
            text += "\n(\(code))"
        }
        return text
    }

    @objc private func handlePrimaryTap() {
        onPrimaryTap?()
    }
}

private final class RadialSpinnerView: UIView {

    private let replicatorLayer = CAReplicatorLayer()
    private let rayLayer = CALayer()
    private let rayCount = 8
    private var isSpinning = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false

        layer.addSublayer(replicatorLayer)
        rayLayer.backgroundColor = KvellDesign.Color.toggleOff.cgColor
        replicatorLayer.addSublayer(rayLayer)

        replicatorLayer.instanceCount = rayCount
        replicatorLayer.instanceTransform = CATransform3DMakeRotation(2 * .pi / CGFloat(rayCount), 0, 0, 1)
        replicatorLayer.instanceAlphaOffset = -1 / Float(rayCount)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        replicatorLayer.frame = bounds

        let radius = bounds.height / 2
        let rayWidth = max(2, bounds.width * 0.09)

        rayLayer.anchorPoint = CGPoint(x: 0.5, y: 1)
        rayLayer.bounds = CGRect(x: 0, y: 0, width: rayWidth, height: radius)
        rayLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        rayLayer.cornerRadius = rayWidth / 2
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, isSpinning {
            addRotationAnimation()
        }
    }

    func startAnimating() {
        isSpinning = true
        addRotationAnimation()
    }

    func stopAnimating() {
        isSpinning = false
        replicatorLayer.removeAnimation(forKey: "rotation")
    }

    private func addRotationAnimation() {
        guard replicatorLayer.animation(forKey: "rotation") == nil else { return }
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = 2 * Double.pi
        rotation.duration = 1
        rotation.repeatCount = .infinity
        replicatorLayer.add(rotation, forKey: "rotation")
    }
}
