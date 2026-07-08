//
//  KvellInputFieldView.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

final class KvellInputFieldView: UIView {

    enum State {
        case normal
        case error
    }

    let textField = UITextField()

    var onTooltipTap: (() -> Void)? {
        didSet { tooltipButton.isHidden = onTooltipTap == nil }
    }

    private let label = UILabel()
    private let tooltipButton = UIButton(type: .custom)
    private let labelRow = UIView()
    private let fieldContainer = UIView()
    private let leadIconView = UIImageView()
    private let fieldStack = UIStackView()

    private var tailView: UIView?
    private var state: State = .normal
    private var isTextFieldFocused = false

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

        setupLabelRow()
        setupFieldContainer()

        let outerStack = UIStackView(arrangedSubviews: [labelRow, fieldContainer])
        outerStack.axis = .vertical
        outerStack.spacing = 0
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(outerStack)
        NSLayoutConstraint.activate(outerStack.pinToSuperviewEdges())

        updateBorderColor()
    }

    private func setupLabelRow() {
        label.numberOfLines = 1
        label.textColor = KvellDesign.Color.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        tooltipButton.setImage(UIImage.named("kv_tooltip"), for: .normal)
        tooltipButton.isHidden = true
        tooltipButton.addTarget(self, action: #selector(handleTooltipTap), for: .touchUpInside)
        tooltipButton.translatesAutoresizingMaskIntoConstraints = false

        labelRow.translatesAutoresizingMaskIntoConstraints = false
        labelRow.addSubview(label)
        labelRow.addSubview(tooltipButton)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: labelRow.topAnchor, constant: 2),
            label.bottomAnchor.constraint(equalTo: labelRow.bottomAnchor, constant: -2),
            label.leadingAnchor.constraint(equalTo: labelRow.leadingAnchor),

            tooltipButton.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            tooltipButton.trailingAnchor.constraint(equalTo: labelRow.trailingAnchor),
            tooltipButton.widthAnchor.constraint(equalToConstant: 24),
            tooltipButton.heightAnchor.constraint(equalToConstant: 24),
            tooltipButton.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: 4)
        ])
    }

    private func setupFieldContainer() {
        fieldContainer.backgroundColor = KvellDesign.Color.surface
        fieldContainer.layer.cornerRadius = KvellDesign.Radius.xl
        fieldContainer.layer.borderWidth = 1
        fieldContainer.translatesAutoresizingMaskIntoConstraints = false
        fieldContainer.heightAnchor.constraint(equalToConstant: 40).isActive = true

        leadIconView.contentMode = .scaleAspectFit
        leadIconView.tintColor = KvellDesign.Color.textSecondary
        leadIconView.isHidden = true
        leadIconView.translatesAutoresizingMaskIntoConstraints = false
        leadIconView.setContentHuggingPriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            leadIconView.widthAnchor.constraint(equalToConstant: 20),
            leadIconView.heightAnchor.constraint(equalToConstant: 20)
        ])

        textField.font = KvellDesign.Font.captionLRegular.font
        textField.textColor = KvellDesign.Color.textPrimary
        textField.borderStyle = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(self, action: #selector(handleEditingBegin), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(handleEditingEnd), for: .editingDidEnd)

        fieldStack.axis = .horizontal
        fieldStack.alignment = .center
        fieldStack.spacing = 8
        fieldStack.translatesAutoresizingMaskIntoConstraints = false
        fieldStack.addArrangedSubview(leadIconView)
        fieldStack.addArrangedSubview(textField)

        fieldContainer.addSubview(fieldStack)
        NSLayoutConstraint.activate([
            fieldStack.topAnchor.constraint(equalTo: fieldContainer.topAnchor, constant: 10),
            fieldStack.bottomAnchor.constraint(equalTo: fieldContainer.bottomAnchor, constant: -10),
            fieldStack.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 12),
            fieldStack.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -12)
        ])
    }

    func setLabel(_ text: String?) {
        label.setStyledText(text, style: KvellDesign.Font.captionLMedium)
        labelRow.isHidden = text == nil
    }

    func setPlaceholder(_ text: String?) {
        guard let text else {
            textField.attributedPlaceholder = nil
            return
        }
        textField.attributedPlaceholder = NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: KvellDesign.Color.textTertiary,
                .font: KvellDesign.Font.captionLRegular.font
            ]
        )
    }

    func setLeadIcon(_ image: UIImage?) {
        leadIconView.image = image
        leadIconView.isHidden = image == nil
    }

    func setTailView(_ view: UIView?) {
        if let tailView {
            fieldStack.removeArrangedSubview(tailView)
            tailView.removeFromSuperview()
        }
        tailView = view
        if let view {
            view.setContentHuggingPriority(.required, for: .horizontal)
            fieldStack.addArrangedSubview(view)
        }
    }

    func setState(_ newState: State) {
        state = newState
        updateBorderColor()
    }

    @objc private func handleTooltipTap() {
        onTooltipTap?()
    }

    @objc private func handleEditingBegin() {
        isTextFieldFocused = true
        updateBorderColor()
    }

    @objc private func handleEditingEnd() {
        isTextFieldFocused = false
        updateBorderColor()
    }

    private func updateBorderColor() {
        switch state {
        case .error:
            fieldContainer.layer.borderColor = UIColor.errorBorder.cgColor
        case .normal:
            fieldContainer.layer.borderColor = (isTextFieldFocused ? KvellDesign.Color.textPrimary : KvellDesign.Color.borderNormal).cgColor
        }
    }
}
