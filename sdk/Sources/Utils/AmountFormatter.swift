//
//  AmountFormatter.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import Foundation

enum AmountFormatter {

    static func format(_ amount: String, currency: String?) -> String {
        guard let value = Decimal(string: amount, locale: Locale(identifier: "en_US")) else {
            return "\(amount) \(resolvedCurrency(currency))"
        }
        return "\(formattedNumber(NSDecimalNumber(decimal: value))) \(resolvedCurrency(currency))"
    }

    static func format(_ amount: Double, currency: String?) -> String {
        "\(formattedNumber(NSNumber(value: amount))) \(resolvedCurrency(currency))"
    }

    private static func resolvedCurrency(_ currency: String?) -> String {
        guard let currency, !currency.isEmpty else { return "RUB" }
        return currency
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = "\u{00A0}"
        formatter.decimalSeparator = ","
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static func formattedNumber(_ number: NSNumber) -> String {
        numberFormatter.string(from: number) ?? number.stringValue
    }
}
