//
//  OrderDetailsView.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

final class OrderDetailsView: UIView {

    var onFeeInfoTap: (() -> Void)?

    private let descriptionLabel = UILabel()
    private let linesStack = UIStackView()

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

        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        linesStack.axis = .vertical
        linesStack.spacing = 8
        linesStack.translatesAutoresizingMaskIntoConstraints = false

        let outer = UIStackView(arrangedSubviews: [descriptionLabel, linesStack])
        outer.axis = .vertical
        outer.spacing = 16
        outer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(outer)

        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            outer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            outer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            outer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
        ])
    }

    func configure(
        description: String?,
        lines: [(title: String, amount: String)],
        fee: (title: String, amount: String)?,
        totalTitle: String,
        totalAmount: String
    ) {
        descriptionLabel.isHidden = description == nil
        if let description {
            descriptionLabel.setStyledText(description, style: KvellDesign.Font.captionLMedium, color: KvellDesign.Color.textPrimary)
        }

        linesStack.arrangedSubviews.forEach {
            linesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for line in lines {
            linesStack.addArrangedSubview(makeLineRow(title: line.title, amount: line.amount))
        }

        if let fee {
            linesStack.addArrangedSubview(makeFeeRow(title: fee.title, amount: fee.amount))
        }

        linesStack.addArrangedSubview(DashedDividerView())
        linesStack.addArrangedSubview(makeTotalRow(title: totalTitle, amount: totalAmount))
    }

    private func makeLineRow(title: String, amount: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.setStyledText(title, style: KvellDesign.Font.captionLRegular, color: KvellDesign.Color.textPrimary)

        let amountLabel = UILabel()
        amountLabel.numberOfLines = 1
        amountLabel.setStyledText(amount, style: KvellDesign.Font.captionLRegular, color: KvellDesign.Color.textPrimary)

        return makeRow(leading: titleLabel, trailing: amountLabel)
    }

    private func makeFeeRow(title: String, amount: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.setStyledText(title, style: KvellDesign.Font.captionLRegular, color: KvellDesign.Color.textPrimary)

        let infoControl = UIControl()
        infoControl.translatesAutoresizingMaskIntoConstraints = false
        infoControl.addTarget(self, action: #selector(handleFeeInfoTap), for: .touchUpInside)

        let infoIcon = UIImageView()
        infoIcon.image = UIImage.named("kv_question")
        infoIcon.tintColor = KvellDesign.Color.textSecondary
        infoIcon.contentMode = .scaleAspectFit
        infoIcon.isUserInteractionEnabled = false
        infoIcon.translatesAutoresizingMaskIntoConstraints = false
        infoControl.addSubview(infoIcon)

        NSLayoutConstraint.activate([
            infoControl.widthAnchor.constraint(equalToConstant: 44),
            infoControl.heightAnchor.constraint(equalToConstant: 44),
            infoIcon.centerXAnchor.constraint(equalTo: infoControl.centerXAnchor),
            infoIcon.centerYAnchor.constraint(equalTo: infoControl.centerYAnchor),
            infoIcon.widthAnchor.constraint(equalToConstant: 16),
            infoIcon.heightAnchor.constraint(equalToConstant: 16)
        ])

        let leadingGroup = UIStackView(arrangedSubviews: [titleLabel, infoControl])
        leadingGroup.axis = .horizontal
        leadingGroup.alignment = .center
        leadingGroup.spacing = 0
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let amountLabel = UILabel()
        amountLabel.numberOfLines = 1
        amountLabel.setStyledText(amount, style: KvellDesign.Font.captionLRegular, color: KvellDesign.Color.textPrimary)

        return makeRow(leading: leadingGroup, trailing: amountLabel)
    }

    private func makeTotalRow(title: String, amount: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        titleLabel.setStyledText(title, style: KvellDesign.Font.bodyMMedium, color: KvellDesign.Color.textPrimary)

        let amountLabel = UILabel()
        amountLabel.numberOfLines = 1
        amountLabel.setStyledText(amount, style: KvellDesign.Font.bodyMMedium, color: KvellDesign.Color.textPrimary)

        return makeRow(leading: titleLabel, trailing: amountLabel)
    }

    private func makeRow(leading: UIView, trailing: UIView) -> UIView {
        leading.setContentHuggingPriority(.defaultLow, for: .horizontal)
        leading.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        trailing.setContentHuggingPriority(.required, for: .horizontal)
        trailing.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [leading, trailing])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 16
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }

    @objc private func handleFeeInfoTap() {
        onFeeInfoTap?()
    }
}
