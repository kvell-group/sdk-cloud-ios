//
//  KvellPrimaryButton.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

final class KvellPrimaryButton: UIControl {

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let textContainer = UIView()
    private let contentStack = UIStackView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private var widthLockConstraint: NSLayoutConstraint?
    private var heightLockConstraint: NSLayoutConstraint?

    override var isHighlighted: Bool {
        didSet { updateAlpha() }
    }

    override var isEnabled: Bool {
        didSet { updateAlpha() }
    }

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
        backgroundColor = KvellDesign.Color.buttonPrimary
        layer.cornerRadius = KvellDesign.Radius.xl

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = KvellDesign.Color.textInverted
        iconView.isHidden = true
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20)
        ])

        titleLabel.numberOfLines = 1
        titleLabel.textColor = KvellDesign.Color.textInverted
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        textContainer.isUserInteractionEnabled = false
        textContainer.translatesAutoresizingMaskIntoConstraints = false
        textContainer.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: textContainer.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor, constant: -4)
        ])

        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 4
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(textContainer)
        addSubview(contentStack)

        activityIndicator.color = KvellDesign.Color.textInverted
        activityIndicator.hidesWhenStopped = true
        activityIndicator.isHidden = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 48),

            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        updateAlpha()
    }

    func configure(title: String, icon: UIImage?) {
        titleLabel.setStyledText(title, style: KvellDesign.Font.bodySMedium)
        iconView.image = icon
        iconView.isHidden = icon == nil
    }

    func setLoading(_ loading: Bool) {
        if loading {
            layoutIfNeeded()
            let size = bounds.size
            if size.width > 0 {
                let widthConstraint = widthAnchor.constraint(equalToConstant: size.width)
                widthConstraint.priority = .defaultHigh
                widthConstraint.isActive = true
                widthLockConstraint = widthConstraint
            }
            let heightConstraint = heightAnchor.constraint(equalToConstant: max(size.height, 48))
            heightConstraint.priority = .defaultHigh
            heightConstraint.isActive = true
            heightLockConstraint = heightConstraint

            contentStack.isHidden = true
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            isUserInteractionEnabled = false
        } else {
            widthLockConstraint?.isActive = false
            widthLockConstraint = nil
            heightLockConstraint?.isActive = false
            heightLockConstraint = nil

            contentStack.isHidden = false
            activityIndicator.stopAnimating()
            isUserInteractionEnabled = true
        }
    }

    private func updateAlpha() {
        if !isEnabled {
            alpha = 0.4
        } else if isHighlighted {
            alpha = 0.85
        } else {
            alpha = 1
        }
    }
}
