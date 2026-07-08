//
//  CardPaymentPageViewController.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

final class CardPaymentPageViewController: BaseViewController {

    var onBack: (() -> Void)?
    var onPatch: ((_ email: String?, _ tokenize: Bool) -> Void)?
    var onPay: ((_ cryptogram: String, _ email: String?) -> Void)?

    private let configuration: PaymentConfiguration
    private let intent: PaymentIntentResponse?
    private let showBackButton: Bool

    private let scaffold = PaymentPageScaffoldView()

    private let cardNumberField = KvellInputFieldView()
    private let expiryField = KvellInputFieldView()
    private let cvvField = KvellInputFieldView()
    private let nameField = KvellInputFieldView()
    private var emailField: KvellInputFieldView?
    private let cardBrandIcon = UIImageView()

    private var saveCardToggle: KvellToggleView?
    private var cvvTooltip: TooltipView?

    private let payButton = KvellPrimaryButton()

    init(
        configuration: PaymentConfiguration,
        intent: PaymentIntentResponse?,
        showBackButton: Bool
    ) {
        self.configuration = configuration
        self.intent = intent
        self.showBackButton = showBackButton
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = KvellDesign.Color.surface
        hideKeyboardWhenTappedAround()

        view.addSubview(scaffold)
        NSLayoutConstraint.activate(scaffold.pinToSuperviewEdges())

        scaffold.orderDetails.configure(with: configuration, intent: intent)
        scaffold.footer.configureDefaultActions()

        setupCardNumberField()
        setupExpiryField()
        setupCvvField()
        setupNameField()
        setupEmailFieldIfNeeded()

        scaffold.setContent(buildContent())
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/methods/card-edit", methodChosen: "Card", cardFieldsCount: 3, eventType: "Open")
        AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/methods/card-edit", cardFieldsCount: 3, eventType: "CardInputShown")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        payButton.setLoading(false)
    }

    override func onKeyboardWillShow(_ notification: Notification) {
        super.onKeyboardWillShow(notification)
        updateScrollInsetForKeyboard()
    }

    override func onKeyboardWillHide(_ notification: Notification) {
        super.onKeyboardWillHide(notification)
        updateScrollInsetForKeyboard()
    }

    private func updateScrollInsetForKeyboard() {
        let bottomInset = isKeyboardShowing ? max(0, keyboardFrame.height - view.safeAreaInsets.bottom) : 0
        UIView.animate(withDuration: 0.25) {
            self.scaffold.scrollView.contentInset.bottom = bottomInset
            self.scaffold.scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
    }

    // MARK: - Content

    private func buildContent() -> UIView {
        var children: [UIView] = []

        if showBackButton {
            let backButton = KvellTertiaryButton()
            backButton.configure(title: "Выбрать другой способ оплаты", icon: UIImage.named("kv_arrow_left"))
            backButton.addTarget(self, action: #selector(handleBackTap), for: .touchUpInside)
            children.append(wrapLeading(backButton))
        }

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        titleLabel.setStyledText("Банковская карта", style: KvellDesign.Font.bodyLBold, color: KvellDesign.Color.textPrimary)
        children.append(titleLabel)

        children.append(buildFormCard())

        if let emailField {
            children.append(emailField)
        }

        if let saveBlock = buildSaveCardBlockIfNeeded() {
            children.append(saveBlock)
        }

        let contentStack = UIStackView(arrangedSubviews: children)
        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)

        let amountText = AmountFormatter.format(configuration.paymentData.amount, currency: configuration.paymentData.currency)
        let paySection = buildPaySection(amountText: amountText)

        let outer = UIStackView(arrangedSubviews: [contentStack, paySection])
        outer.axis = .vertical
        outer.spacing = 0
        return outer
    }

    private func wrapLeading(_ view: UIView) -> UIView {
        let container = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor)
        ])
        return container
    }

    // MARK: - Form card

    private func buildFormCard() -> UIView {
        let card = UIView()
        card.backgroundColor = KvellDesign.Color.surface
        card.layer.borderWidth = 1
        card.layer.borderColor = KvellDesign.Color.borderAlpha.cgColor
        card.layer.cornerRadius = KvellDesign.Radius.xxxl
        card.layer.shadowColor = UIColor(red: 20, green: 21, blue: 26, alpha: 0.05).cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.layer.shadowRadius = 12
        card.layer.shadowOpacity = 1

        let expiryCvvRow = UIStackView(arrangedSubviews: [expiryField, cvvField])
        expiryCvvRow.axis = .horizontal
        expiryCvvRow.alignment = .fill
        expiryCvvRow.spacing = 16

        let stack = UIStackView(arrangedSubviews: [makeFormHeaderRow(), cardNumberField, expiryCvvRow, nameField])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20)
        ])
        return card
    }

    private func makeFormHeaderRow() -> UIView {
        let icon = UIImageView(image: UIImage.named("kv_bank_cards_small"))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24)
        ])

        let label = UILabel()
        label.numberOfLines = 1
        label.setStyledText("Данные карты", style: KvellDesign.Font.bodySSemiBold, color: KvellDesign.Color.textPrimary)

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        return row
    }

    private func setupCardNumberField() {
        cardNumberField.setLabel("Номер карты")
        cardNumberField.setPlaceholder("0000 0000 0000 0000")
        cardNumberField.setLeadIcon(UIImage.named("kv_card"))
        cardNumberField.textField.keyboardType = .numberPad

        cardBrandIcon.contentMode = .scaleAspectFit
        cardBrandIcon.isHidden = true
        cardBrandIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardBrandIcon.widthAnchor.constraint(equalToConstant: 28),
            cardBrandIcon.heightAnchor.constraint(equalToConstant: 20)
        ])
        cardNumberField.setTailView(cardBrandIcon)

        cardNumberField.textField.addTarget(self, action: #selector(handleCardNumberChanged), for: .editingChanged)
        cardNumberField.textField.addTarget(self, action: #selector(handleCardNumberEndEditing), for: .editingDidEnd)
    }

    private func setupExpiryField() {
        expiryField.setLabel("Срок действия")
        expiryField.setPlaceholder("ММ/ГГ")
        expiryField.setLeadIcon(UIImage.named("kv_calendar"))
        expiryField.textField.keyboardType = .numberPad
        expiryField.textField.addTarget(self, action: #selector(handleExpiryChanged), for: .editingChanged)
        expiryField.textField.addTarget(self, action: #selector(handleExpiryEndEditing), for: .editingDidEnd)
    }

    private func setupCvvField() {
        cvvField.setLabel("CVV/CVC")
        cvvField.setPlaceholder("···")
        cvvField.textField.keyboardType = .numberPad
        cvvField.textField.isSecureTextEntry = true
        cvvField.onTooltipTap = { [weak self] in self?.toggleCvvTooltip() }
        cvvField.textField.addTarget(self, action: #selector(handleCvvChanged), for: .editingChanged)
        cvvField.textField.addTarget(self, action: #selector(handleCvvEndEditing), for: .editingDidEnd)
        cvvField.widthAnchor.constraint(equalToConstant: 144).isActive = true
    }

    private func setupNameField() {
        nameField.setLabel("Имя на карте")
        nameField.setPlaceholder("IVAN IVANOV")
        nameField.textField.autocapitalizationType = .allCharacters
        nameField.textField.autocorrectionType = .no
        nameField.textField.delegate = self
    }

    private func setupEmailFieldIfNeeded() {
        guard configuration.emailBehavior != .hidden else { return }

        let field = KvellInputFieldView()
        field.setLabel("Email для чека")
        field.setPlaceholder("email@example.com")
        field.textField.keyboardType = .emailAddress
        field.textField.autocapitalizationType = .none
        field.textField.autocorrectionType = .no
        field.textField.text = configuration.paymentData.email
        field.textField.addTarget(self, action: #selector(handleEmailEndEditing), for: .editingDidEnd)
        emailField = field
    }

    // MARK: - Save card block

    private func buildSaveCardBlockIfNeeded() -> UIView? {
        guard let state = configuration.paymentData.intentSaveCardState else { return nil }
        guard state == .optional || state == .force else { return nil }

        let container = UIView()
        container.layer.borderWidth = 1
        container.layer.borderColor = KvellDesign.Color.borderNormal.cgColor
        container.layer.cornerRadius = KvellDesign.Radius.xl

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        titleLabel.setStyledText("Сохранить карту в KVELL.Pay", style: KvellDesign.Font.captionLMedium, color: KvellDesign.Color.textPrimary)

        let subtitleLabel = UILabel()
        subtitleLabel.numberOfLines = 0
        subtitleLabel.setStyledText(
            "Безопасно храните ваши карты для быстрой оплаты по номеру телефона",
            style: KvellDesign.Font.captionLRegular,
            color: KvellDesign.Color.textSecondary
        )

        let textColumn = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textColumn.axis = .vertical
        textColumn.spacing = 4

        var rowViews: [UIView] = []
        if state == .optional {
            let toggle = KvellToggleView()
            toggle.isOn = configuration.paymentData.savedTokenize ?? false
            saveCardToggle = toggle
            rowViews.append(toggle)
        }
        rowViews.append(textColumn)

        let row = UIStackView(arrangedSubviews: rowViews)
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 16
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

    private var effectiveTokenize: Bool {
        if let saveCardToggle { return saveCardToggle.isOn }
        return configuration.paymentData.intentSaveCardState == .force
    }

    // MARK: - Pay section

    private func buildPaySection(amountText: String) -> UIView {
        payButton.configure(title: "Оплатить \(amountText)", icon: UIImage.named("kv_lock"))
        payButton.addTarget(self, action: #selector(handlePayTap), for: .touchUpInside)

        let captionLabel = UILabel()
        captionLabel.numberOfLines = 0
        captionLabel.textAlignment = .center
        captionLabel.attributedText = makeAgreementAttributedString()
        captionLabel.isUserInteractionEnabled = true
        captionLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleAgreementTap)))

        let section = UIStackView(arrangedSubviews: [payButton, captionLabel])
        section.axis = .vertical
        section.spacing = 16
        section.isLayoutMarginsRelativeArrangement = true
        section.layoutMargins = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        return section
    }

    private func makeAgreementAttributedString() -> NSAttributedString {
        let style = KvellDesign.Font.captionLRegular
        let text = "Нажимая на кнопку, вы соглашаетесь с условиями оплаты"

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = style.lineHeight
        paragraphStyle.maximumLineHeight = style.lineHeight
        paragraphStyle.alignment = .center

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

        let range = (text as NSString).range(of: "условиями оплаты")
        result.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        return result
    }

    @objc private func handleAgreementTap() {
        guard let path = intent?.terminalInfo?.agreementPath ?? intent?.offerLink, let url = URL(string: path) else { return }
        present(SafariViewController(url: url), animated: true)
    }

    // MARK: - Field handlers

    @objc private func handleCardNumberChanged() {
        cardNumberField.textField.text = cardNumberField.textField.text?.formattedCardNumber()
        cardNumberField.setState(.normal)

        let clean = Card.cleanCreditCardNo(cardNumberField.textField.text ?? "")
        let type = Card.cardType(from: clean)
        if type != .unknown, let icon = type.getIcon() {
            cardBrandIcon.image = icon
            cardBrandIcon.isHidden = false
        } else {
            cardBrandIcon.isHidden = true
        }
    }

    @objc private func handleCardNumberEndEditing() {
        let hasText = !(cardNumberField.textField.text ?? "").isEmpty
        let isValid = Card.isCardNumberValid(cardNumberField.textField.text)
        cardNumberField.setState(hasText && !isValid ? .error : .normal)
    }

    @objc private func handleExpiryChanged() {
        expiryField.textField.text = expiryField.textField.text?.formattedCardExp()
        expiryField.setState(.normal)
    }

    @objc private func handleExpiryEndEditing() {
        let hasText = !(expiryField.textField.text ?? "").isEmpty
        let isValid = Card.isExpDateValid(expiryField.textField.text)
        expiryField.setState(hasText && !isValid ? .error : .normal)
    }

    @objc private func handleCvvChanged() {
        cvvField.textField.text = cvvField.textField.text?.formattedCardCVV()
        cvvField.setState(.normal)
    }

    @objc private func handleCvvEndEditing() {
        let hasText = !(cvvField.textField.text ?? "").isEmpty
        let isValid = Card.isValidCvv(cvv: cvvField.textField.text)
        cvvField.setState(hasText && !isValid ? .error : .normal)
    }

    @objc private func handleEmailEndEditing() {
        emailField?.setState(isEmailValid() ? .normal : .error)
    }

    private func toggleCvvTooltip() {
        if let cvvTooltip {
            cvvTooltip.removeFromSuperview()
            self.cvvTooltip = nil
            return
        }

        let tooltip = TooltipView(texts: ["Три цифры с обратной стороны карты"])
        tooltip.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tooltip)

        let anchorFrame = cvvField.convert(cvvField.bounds, to: view)
        NSLayoutConstraint.activate([
            tooltip.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            tooltip.widthAnchor.constraint(equalToConstant: 220),
            tooltip.topAnchor.constraint(equalTo: view.topAnchor, constant: anchorFrame.maxY + 8)
        ])
        cvvTooltip = tooltip
    }

    @objc private func handleBackTap() {
        onBack?()
    }

    // MARK: - Validation

    private func isEmailValid() -> Bool {
        guard let emailField else { return true }
        let trimmed = emailField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        switch configuration.emailBehavior {
        case .required:
            return !trimmed.isEmpty && trimmed.emailIsValid()
        case .optional:
            return trimmed.isEmpty || trimmed.emailIsValid()
        case .hidden:
            return true
        }
    }

    private func scrollToFirstError(cardOk: Bool, expOk: Bool, cvvOk: Bool, emailOk: Bool) {
        let firstInvalid: UIView?
        if !cardOk {
            firstInvalid = cardNumberField
        } else if !expOk {
            firstInvalid = expiryField
        } else if !cvvOk {
            firstInvalid = cvvField
        } else if !emailOk {
            firstInvalid = emailField
        } else {
            firstInvalid = nil
        }

        guard let firstInvalid else { return }
        let scrollView = scaffold.scrollView
        let targetRect = firstInvalid.convert(firstInvalid.bounds, to: scrollView)
        scrollView.scrollRectToVisible(targetRect.insetBy(dx: 0, dy: -24), animated: true)
    }

    // MARK: - Pay

    @objc private func handlePayTap() {
        view.endEditing(true)

        let cardNumber = cardNumberField.textField.text ?? ""
        let expiry = expiryField.textField.text ?? ""
        let cvv = cvvField.textField.text ?? ""
        let name = nameField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailField?.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        let isCardValid = Card.isCardNumberValid(cardNumber)
        let isExpValid = Card.isExpDateValid(expiry)
        let isCvvValid = Card.isValidCvv(cvv: cvv)
        let isEmailOk = isEmailValid()

        cardNumberField.setState(isCardValid ? .normal : .error)
        expiryField.setState(isExpValid ? .normal : .error)
        cvvField.setState(isCvvValid ? .normal : .error)
        emailField?.setState(isEmailOk ? .normal : .error)

        guard isCardValid, isExpValid, isCvvValid, isEmailOk else {
            scrollToFirstError(cardOk: isCardValid, expOk: isExpValid, cvvOk: isCvvValid, emailOk: isEmailOk)
            return
        }

        if !name.isEmpty {
            _ = configuration.paymentData.setCardholderName(name)
        }

        onPatch?(email, effectiveTokenize)

        guard let pem = configuration.paymentData.pem, let version = configuration.paymentData.version else { return }

        guard let cryptogram = Card.makeCardCryptogramPacket(
            cardNumber: cardNumber,
            expDate: expiry,
            cvv: cvv,
            merchantPublicID: configuration.publicId,
            publicKey: pem,
            keyVersion: version
        ) else {
            showAlert(title: .errorWord, message: .errorCreatingCryptoPacket)
            return
        }

        AnalyticsService.shared.sendActionClickEvent(
            configuration: configuration,
            elementLabel: "PayByCard",
            elementType: "Button",
            actionType: "Click",
            screenName: "/methods/card-edit",
            methodChosen: "Card",
            actionContext: "Valid"
        )

        payButton.setLoading(true)
        onPay?(cryptogram, email)
    }
}

// MARK: - UITextFieldDelegate

extension CardPaymentPageViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField === nameField.textField, !string.isEmpty else { return true }

        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz -")
        return string.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}
