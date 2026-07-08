//
//  OrderDetailsView+PaymentConfiguration.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

extension OrderDetailsView {

    func configure(with configuration: PaymentConfiguration, intent: PaymentIntentResponse?) {
        let paymentData = configuration.paymentData
        let currency = paymentData.currency

        let lines = paymentData.orderLines.map { line in
            (title: line.title, amount: AmountFormatter.format(line.amount, currency: currency))
        }

        var fee: (title: String, amount: String)?
        if let payerServiceFee = intent?.payerServiceFee, !payerServiceFee.isEmpty {
            fee = (title: "Комиссия платёжной системы", amount: AmountFormatter.format(payerServiceFee, currency: currency))
        }

        configure(
            description: paymentData.description,
            lines: lines,
            fee: fee,
            totalTitle: "Итого",
            totalAmount: AmountFormatter.format(paymentData.amount, currency: currency)
        )
    }
}
