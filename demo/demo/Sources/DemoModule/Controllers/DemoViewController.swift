//
//  DemoViewController.swift
//  demo
//
//  Created by Kvell on 31/05/2019.
//  Copyright © 2019 Kvell. All rights reserved.
//

import UIKit
import Kvell
import KvellNetworking
import KvellDevKit

final class DemoViewController: BaseViewController {

    // MARK: - Private properties

    @IBOutlet private weak var tableView: UITableView!

    private var viewModels = PaymentViewModel.getViewModel()
    private let header = LogoHeaderView()
    private let footer = FooterActionView()

    /// 0 = Dev backend, 1 = Mock: success, 2 = Mock: 3DS, 3 = Mock: decline
    private let modeSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Dev backend", "Mock: success", "Mock: 3DS", "Mock: decline"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        view.addGestureRecognizer(tap)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Logs",
            style: .plain,
            target: self,
            action: #selector(showLogs)
        )
    }

    @objc private func showLogs() {
        let logsController = LogsViewController()
        if let navigationController = navigationController {
            navigationController.pushViewController(logsController, animated: true)
        } else {
            present(UINavigationController(rootViewController: logsController), animated: true)
        }
    }

    @objc private func tapAction() {
        view.endEditing(true)
    }
    
    // MARK: - Private methods
    private func setupTableView() {
        view.backgroundColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        configureHeaderAndFooter(tableView)
    }
    
    private func configureHeaderAndFooter(_ tableView: UITableView) {

        enum Constants: CGFloat {
            case headerHeight = 80
            case footerWidth = 250
            case footerHeight = 200
            case position = 0

            func toCGFloat() -> CGFloat { return self.rawValue }
        }

        // Оборачиваем LogoHeaderView + UISegmentedControl в одну containerView
        let segmentHeight: CGFloat = 44
        let padding: CGFloat = 8
        let totalHeaderHeight = Constants.headerHeight.toCGFloat() + segmentHeight + padding * 2
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: totalHeaderHeight))

        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: Constants.headerHeight.toCGFloat())
        containerView.addSubview(header)

        modeSegment.frame = CGRect(x: 8, y: Constants.headerHeight.toCGFloat() + padding, width: view.bounds.width - 16, height: segmentHeight)
        containerView.addSubview(modeSegment)

        tableView.tableHeaderView = containerView

        footer.frame = CGRect(x: Constants.position.toCGFloat(), y: Constants.position.toCGFloat(), width: Constants.footerWidth.toCGFloat(), height: Constants.footerHeight.toCGFloat())
        footer.addTarget(target: self, action: #selector(run(_:)), .demo)
        tableView.tableFooterView = footer
    }
    
    func getText(_ type: PaymentViewModelType) -> String? {
        for value in viewModels {
            if value.type == type { return value.text }
        }
        return nil
    }
    
    // MARK: - Standart Form
    
    @objc private func run(_ sender: UIButton) {
        
        PaymentViewModel.saving(viewModels)
    
        guard let publicId =  getText(.publicId),
              let apiUrl = getText(.apiUrl),
              let amount = getText(.amount),
              let currency = getText(.currency),
              let invoiceId =  getText(.invoiceId),
              let descript = getText(.description),
              let account = getText(.accountId),
              let email = getText(.email),
              let payerFirstName = getText(.payerFirstName),
              let payerLastName = getText(.payerLastName),
              let payerMiddleName = getText(.payerMiddleName),
              let payerBirthday = getText(.payerBirthday),
              let payerAddress = getText(.payerAddress),
              let payerStreet = getText(.payerStreet),
              let payerCity = getText(.payerCity),
              let payerCountry = getText(.payerCountry),
              let payerPhone = getText(.payerPhone),
              let payerPostcode = getText(.payerPostcode),
              let jsonData = getText(.jsonData)
        else { return }
        
        let receipt: [String: Any] = [
            "Items": [
                [
                    "label": "Товар",
                    "price": 1.95,
                    "quantity": 1,
                    "amount": 1.95,
                    "vat": 0,
                    "method": 4,
                    "object": 1
                ]
            ],
            "taxationSystem": 0,
            "email": "test@test.ru",
            "amounts": [
                "electronic": 1.95,
                "advancePayment": 0,
                "credit": 0,
                "provision": 0
            ]
        ]
                
        let recurrent = Recurrent(
            interval: "Week",
            period: 1,
            receipt: receipt,
            amount: 730.65
        )
        
        let payer = PaymentDataPayer(
            firstName: payerFirstName,
            lastName: payerLastName,
            middleName: payerMiddleName,
            birth: payerBirthday,
            address: payerAddress,
            street: payerStreet,
            city: payerCity,
            country: payerCountry,
            phone: payerPhone,
            postcode: payerPostcode
        )
        
        // В Dev backend каждый charge должен иметь уникальный InvoiceId — иначе бэк отвергает дубликат заказа.
        let isDevBackend = modeSegment.selectedSegmentIndex == 0
        let effectiveInvoiceId = isDevBackend ? "KVELL-" + String(UUID().uuidString.prefix(8)) : invoiceId

        let paymentData = PaymentData()
            .setAmount(amount)
            .setCurrency(currency)
            .setCardholderName("CP SDK")
            .setInvoiceId(effectiveInvoiceId)
            .setDescription(descript)
            .setAccountId(account)
            .setPayer(payer)
            .setEmail(email)
            .setJsonData(jsonData)
            .setReceipt(receipt)
            .setRecurrent(recurrent)
        
        // Выбор режима по segmented control:
        // 0 = Dev backend (живой classic charge + лог HTTP), 1 = Mock: success, 2 = Mock: 3DS, 3 = Mock: decline
        // Все данные окружения (URL, ApiSecret) берутся из полей формы — в коде хардкодов нет.
        let dispatcher: KvellNetworkDispatcher?
        switch modeSegment.selectedSegmentIndex {
        case 1:
            dispatcher = MockNetworkDispatcher(scenario: .success)
        case 2:
            dispatcher = MockNetworkDispatcher(scenario: .requires3DS)
        case 3:
            dispatcher = MockNetworkDispatcher(scenario: .decline)
        default:
            dispatcher = LoggingNetworkDispatcher()
        }

        let apiSecretText = getText(.apiSecret) ?? ""
        let apiSecret: String? = (isDevBackend && !apiSecretText.isEmpty) ? apiSecretText : nil

        let configuration = PaymentConfiguration(
            publicId: publicId,
            apiSecret: apiSecret,
            paymentData: paymentData,
            delegate: self,
            uiDelegate: self,
            emailBehavior: .optional,
            paymentMethodSequence: [],
//            singlePaymentMode: .tpay,
            useDualMessagePayment: footer.demoActionSwitch.isOn,
            apiUrl: apiUrl,
            showResultScreenForSinglePaymentMode: true,
            // successRedirectUrl: "https://ya.ru",
            // failRedirectUrl: "https://ya.ru",
            networkDispatcher: dispatcher
        )

        PaymentOptionsViewController.present(with: configuration, from: self)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension DemoViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DemoViewCell.identifier, for: indexPath) as? DemoViewCell else {
            return UITableViewCell()
        }
        let value = viewModels[indexPath.row]
        cell.setupView(viewModel: value)
        cell.addTarget(self, action: #selector(textFieldEditing(_:)), row: indexPath.row)
        return cell
    }
    
    @objc private func textFieldEditing(_ textField: UITextField) {
        let row = textField.tag
        viewModels[row].text = textField.text
    }
}

// MARK: - PaymentDelegate
extension DemoViewController: PaymentDelegate {
    func onPaymentClosed() {
        print("Payment form was closed")
    }
        
    func onPaymentFinished(_ transactionId: Int64?) {
        navigationController?.popViewController(animated: true)
        
        if let transactionId = transactionId {
            print("Transaction finished with ID: \(transactionId)")
        }
    }

    func onPaymentFailed(_ errorMessage: String?) {
        if let errorMessage = errorMessage {
            print("Transaction failed with error: \(errorMessage)")
        }
    }
}

extension DemoViewController: PaymentUIDelegate {
    func paymentFormWillDisplay() {
        print("Payment form will display")
    }
    
    func paymentFormDidDisplay() {
        print("Payment form did display")
    }
    
    func paymentFormWillHide() {
        print("Payment form will hide")
    }
    
    func paymentFormDidHide() {
        print("Payment form did hide")
    }
}

