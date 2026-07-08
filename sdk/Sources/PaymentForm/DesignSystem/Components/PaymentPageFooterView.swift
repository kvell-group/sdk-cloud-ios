//
//  PaymentPageFooterView.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

final class PaymentPageFooterView: UIView {

    var onPhoneTap: (() -> Void)?
    var onEmailTap: (() -> Void)?
    var onKvellTap: (() -> Void)?

    private let kvellLabel = UILabel()
    private let phoneGroup = TappableStack(spacing: 4)
    private let emailGroup = TappableStack(spacing: 4)

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

        let securityRow = makeSecurityRow()
        let kvellColumn = makeKvellColumn()
        let paymentSystemsRow = makePaymentSystemsRow()

        let outer = UIStackView(arrangedSubviews: [securityRow, kvellColumn, paymentSystemsRow])
        outer.axis = .vertical
        outer.spacing = 32
        outer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(outer)

        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: topAnchor, constant: 32),
            outer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -32),
            outer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            outer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32)
        ])

        phoneGroup.onTap = { [weak self] in self?.onPhoneTap?() }
        emailGroup.onTap = { [weak self] in self?.onEmailTap?() }

        let kvellTap = UITapGestureRecognizer(target: self, action: #selector(handleKvellTap))
        kvellLabel.isUserInteractionEnabled = true
        kvellLabel.addGestureRecognizer(kvellTap)
    }

    private func makeSecurityRow() -> UIView {
        let icon = UIImageView()
        icon.image = UIImage.named("kv_security")
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 32),
            icon.heightAnchor.constraint(equalToConstant: 32)
        ])

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        titleLabel.setStyledText("Безопасный платёж", style: KvellDesign.Font.bodySRegular, color: KvellDesign.Color.textPrimary)

        let subtitleLabel = UILabel()
        subtitleLabel.numberOfLines = 0
        subtitleLabel.setStyledText(
            "Все данные зашифрованы и передаются\nпо защищённому протоколу TLS v1.2",
            style: KvellDesign.Font.captionMRegular,
            color: KvellDesign.Color.textSecondary
        )

        let column = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        column.axis = .vertical
        column.spacing = 4

        let row = UIStackView(arrangedSubviews: [icon, column])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 16
        return row
    }

    private func makeKvellColumn() -> UIView {
        kvellLabel.numberOfLines = 1
        kvellLabel.attributedText = makeKvellAttributedString()

        let phoneIcon = UIImageView()
        phoneIcon.image = UIImage.named("kv_phone")
        phoneIcon.tintColor = KvellDesign.Color.textSecondary
        phoneIcon.contentMode = .scaleAspectFit
        phoneIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            phoneIcon.widthAnchor.constraint(equalToConstant: 20),
            phoneIcon.heightAnchor.constraint(equalToConstant: 20)
        ])

        let phoneLabel = UILabel()
        phoneLabel.numberOfLines = 1
        phoneLabel.setStyledText("+7 (495) 120-22-50", style: KvellDesign.Font.captionLRegular, color: KvellDesign.Color.textSecondary)

        phoneGroup.setArrangedSubviews([phoneIcon, phoneLabel])

        let mailIcon = UIImageView()
        mailIcon.image = UIImage.named("kv_mail")
        mailIcon.tintColor = KvellDesign.Color.textSecondary
        mailIcon.contentMode = .scaleAspectFit
        mailIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mailIcon.widthAnchor.constraint(equalToConstant: 20),
            mailIcon.heightAnchor.constraint(equalToConstant: 20)
        ])

        let mailLabel = UILabel()
        mailLabel.numberOfLines = 1
        mailLabel.setStyledText("support@kvell.ru", style: KvellDesign.Font.captionLRegular, color: KvellDesign.Color.textSecondary)

        emailGroup.setArrangedSubviews([mailIcon, mailLabel])

        let separator = UIView()
        separator.backgroundColor = KvellDesign.Color.divider
        separator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            separator.widthAnchor.constraint(equalToConstant: 1),
            separator.heightAnchor.constraint(equalToConstant: 20)
        ])

        let contactsRow = UIStackView(arrangedSubviews: [phoneGroup, separator, emailGroup])
        contactsRow.axis = .horizontal
        contactsRow.alignment = .center
        contactsRow.spacing = 12

        let column = UIStackView(arrangedSubviews: [kvellLabel, contactsRow])
        column.axis = .vertical
        column.spacing = 16
        return column
    }

    private func makeKvellAttributedString() -> NSAttributedString {
        let style = KvellDesign.Font.bodySRegular

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = style.lineHeight
        paragraphStyle.maximumLineHeight = style.lineHeight

        let text = "Разработано в KVELL"
        let baselineOffset = (style.lineHeight - style.font.lineHeight) / 4

        let result = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: style.font,
                .kern: style.letterSpacing,
                .paragraphStyle: paragraphStyle,
                .baselineOffset: baselineOffset,
                .foregroundColor: KvellDesign.Color.textSecondary
            ]
        )

        let kvellRange = (text as NSString).range(of: "KVELL")
        result.addAttributes(
            [
                .foregroundColor: KvellDesign.Color.textPrimary,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ],
            range: kvellRange
        )

        return result
    }

    private func makePaymentSystemsRow() -> UIView {
        let visa = makeLogoView(name: "kv_ps_visa", size: CGSize(width: 46, height: 15))
        let mastercard = makeLogoView(name: "kv_ps_mastercard", size: CGSize(width: 37, height: 23))
        let mir = makeLogoView(name: "kv_ps_mir", size: CGSize(width: 62, height: 19))
        let unionpay = makeLogoView(name: "kv_ps_unionpay", size: CGSize(width: 37, height: 23))
        let pci = makeLogoView(name: "kv_ps_pci", size: CGSize(width: 34, height: 23))

        let row = UIStackView(arrangedSubviews: [visa, mastercard, mir, unionpay, pci])
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .equalSpacing
        row.alpha = 0.6
        return row
    }

    private func makeLogoView(name: String, size: CGSize) -> UIView {
        let imageView = UIImageView()
        imageView.image = UIImage.named(name)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: size.width),
            imageView.heightAnchor.constraint(equalToConstant: size.height)
        ])
        return imageView
    }

    @objc private func handleKvellTap() {
        onKvellTap?()
    }
}

private final class TappableStack: UIControl {

    var onTap: (() -> Void)?

    private let stack: UIStackView

    init(spacing: CGFloat) {
        stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = spacing
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate(stack.pinToSuperviewEdges())

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setArrangedSubviews(_ views: [UIView]) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        views.forEach { stack.addArrangedSubview($0) }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
