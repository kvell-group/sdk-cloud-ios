//
//  PaymentMethodRowView.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

final class PaymentMethodRowView: UIControl {

    enum Style {
        case regular
        case kvellPay
    }

    var onTap: (() -> Void)?

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.7 : 1 }
    }

    private let logoContainer = UIView()
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let gradientLayer = CAGradientLayer()

    private var logoWidthConstraint: NSLayoutConstraint?
    private var logoHeightConstraint: NSLayoutConstraint?
    private var currentStyle: Style = .regular

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
        heightAnchor.constraint(equalToConstant: 64).isActive = true

        layer.cornerRadius = KvellDesign.Radius.lg
        layer.borderWidth = 1
        layer.shadowColor = UIColor(red: 20, green: 21, blue: 26, alpha: 0.05).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 1
        layer.shadowOpacity = 1

        gradientLayer.colors = [KvellDesign.Color.kvellPayGradientTop.cgColor, KvellDesign.Color.kvellPayGradientBottom.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.cornerRadius = KvellDesign.Radius.lg
        gradientLayer.masksToBounds = true

        logoContainer.isUserInteractionEnabled = false
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.widthAnchor.constraint(equalToConstant: 56).isActive = true

        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor)
        ])

        titleLabel.numberOfLines = 1
        subtitleLabel.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.isUserInteractionEnabled = false

        let contentStack = UIStackView(arrangedSubviews: [logoContainer, textStack])
        contentStack.axis = .horizontal
        contentStack.alignment = .fill
        contentStack.spacing = 12
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        applyStyle(.regular)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func configure(logo: UIImage?, logoSize: CGSize, title: String, subtitle: String?, style: Style) {
        logoImageView.image = logo

        logoWidthConstraint?.isActive = false
        logoHeightConstraint?.isActive = false
        let widthConstraint = logoImageView.widthAnchor.constraint(equalToConstant: logoSize.width)
        let heightConstraint = logoImageView.heightAnchor.constraint(equalToConstant: logoSize.height)
        widthConstraint.isActive = true
        heightConstraint.isActive = true
        logoWidthConstraint = widthConstraint
        logoHeightConstraint = heightConstraint

        titleLabel.setStyledText(title, style: KvellDesign.Font.bodySMedium, color: KvellDesign.Color.textPrimary)

        subtitleLabel.isHidden = subtitle == nil
        if let subtitle {
            subtitleLabel.setStyledText(subtitle, style: KvellDesign.Font.captionLRegular, color: KvellDesign.Color.textSecondary)
        }

        applyStyle(style)
    }

    private func applyStyle(_ style: Style) {
        currentStyle = style

        switch style {
        case .regular:
            gradientLayer.removeFromSuperlayer()
            backgroundColor = KvellDesign.Color.surface
            layer.borderColor = KvellDesign.Color.borderNormal.cgColor
        case .kvellPay:
            backgroundColor = .clear
            gradientLayer.frame = bounds
            layer.insertSublayer(gradientLayer, at: 0)
            layer.borderColor = KvellDesign.Color.borderAlpha.cgColor
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
