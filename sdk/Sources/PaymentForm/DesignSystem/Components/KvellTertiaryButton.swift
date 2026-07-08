//
//  KvellTertiaryButton.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

final class KvellTertiaryButton: UIControl {

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let textContainer = UIView()
    private let contentStack = UIStackView()

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
        backgroundColor = KvellDesign.Color.buttonTertiary
        layer.cornerRadius = KvellDesign.Radius.xl

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = KvellDesign.Color.textPrimary
        iconView.isHidden = true
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20)
        ])

        titleLabel.numberOfLines = 1
        titleLabel.textColor = KvellDesign.Color.textPrimary
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

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])

        updateAlpha()
    }

    func configure(title: String, icon: UIImage?) {
        titleLabel.setStyledText(title, style: KvellDesign.Font.captionLMedium)
        iconView.image = icon
        iconView.isHidden = icon == nil
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
