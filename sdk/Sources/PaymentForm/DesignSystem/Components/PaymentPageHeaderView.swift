//
//  PaymentPageHeaderView.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

final class PaymentPageHeaderView: UIView {

    var onClose: (() -> Void)? {
        didSet { updateCloseButtonVisibility() }
    }

    private var isCloseEnabled = true

    private let logoImageView = UIImageView()
    private let badgeContainer = UIView()
    private let clockImageView = UIImageView()
    private let timeLabel = UILabel()
    private let closeButton = UIButton(type: .system)

    private var badgeTrailingToHeader: NSLayoutConstraint!
    private var badgeTrailingToCloseButton: NSLayoutConstraint!

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

        logoImageView.image = UIImage.named("kv_logo")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(logoImageView)

        clockImageView.image = UIImage.named("kv_clock")
        clockImageView.tintColor = KvellDesign.Color.textSecondary
        clockImageView.contentMode = .scaleAspectFit
        clockImageView.translatesAutoresizingMaskIntoConstraints = false

        timeLabel.textColor = KvellDesign.Color.textSecondary
        timeLabel.numberOfLines = 1
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        badgeContainer.backgroundColor = KvellDesign.Color.surface
        badgeContainer.layer.cornerRadius = KvellDesign.Radius.md
        badgeContainer.translatesAutoresizingMaskIntoConstraints = false
        badgeContainer.addSubview(clockImageView)
        badgeContainer.addSubview(timeLabel)
        addSubview(badgeContainer)

        let closeIconConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: closeIconConfiguration), for: .normal)
        closeButton.tintColor = KvellDesign.Color.textSecondary
        closeButton.isHidden = true
        closeButton.addTarget(self, action: #selector(handleCloseTap), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton)

        badgeTrailingToHeader = badgeContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
        badgeTrailingToCloseButton = badgeContainer.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8)

        NSLayoutConstraint.activate([
            logoImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            logoImageView.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            logoImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            logoImageView.widthAnchor.constraint(equalToConstant: 149),
            logoImageView.heightAnchor.constraint(equalToConstant: 40),

            badgeContainer.centerYAnchor.constraint(equalTo: logoImageView.centerYAnchor),
            badgeContainer.leadingAnchor.constraint(greaterThanOrEqualTo: logoImageView.trailingAnchor, constant: 8),

            clockImageView.leadingAnchor.constraint(equalTo: badgeContainer.leadingAnchor, constant: 4),
            clockImageView.centerYAnchor.constraint(equalTo: badgeContainer.centerYAnchor),
            clockImageView.widthAnchor.constraint(equalToConstant: 16),
            clockImageView.heightAnchor.constraint(equalToConstant: 16),

            timeLabel.leadingAnchor.constraint(equalTo: clockImageView.trailingAnchor, constant: 4),
            timeLabel.trailingAnchor.constraint(equalTo: badgeContainer.trailingAnchor, constant: -4),
            timeLabel.topAnchor.constraint(equalTo: badgeContainer.topAnchor, constant: 4),
            timeLabel.bottomAnchor.constraint(equalTo: badgeContainer.bottomAnchor, constant: -4),

            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            closeButton.centerYAnchor.constraint(equalTo: logoImageView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        badgeTrailingToHeader.isActive = true

        setRemainingTime(nil)
    }

    func setRemainingTime(_ text: String?) {
        badgeContainer.isHidden = text == nil
        if let text {
            timeLabel.setStyledText(text, style: KvellDesign.Font.captionLMedium)
        }
    }

    func setCloseEnabled(_ enabled: Bool) {
        isCloseEnabled = enabled
        updateCloseButtonVisibility()
    }

    @objc private func handleCloseTap() {
        onClose?()
    }

    private func updateCloseButtonVisibility() {
        let hasClose = onClose != nil && isCloseEnabled
        closeButton.isHidden = !hasClose
        badgeTrailingToHeader.isActive = !hasClose
        badgeTrailingToCloseButton.isActive = hasClose
    }
}
