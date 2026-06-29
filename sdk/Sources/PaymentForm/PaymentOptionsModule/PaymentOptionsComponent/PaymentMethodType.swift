//
//  PaymentMethodType.swift
//  sdk
//
//  Created by Kvell on 29.07.2025.
//  Copyright © 2025 Kvell. All rights reserved.
//

import UIKit
import Foundation

public enum PaymentMethodType: String, CaseIterable {
    case card = "Card"
}

extension PaymentMethodType {

    var buttonTitle: String? {
        switch self {
        case .card:
            return "Банковская карта"
        }
    }

    var buttonIcon: UIImage? {
        switch self {
        case .card: return nil
        }
    }

    var additionalButtonIcon: UIImage? {
        switch self {
        case .card: return .iconCardAdditional
        }
    }

    var backgroundColor: UIColor? {
        switch self {
        case .card: return .colorBlue
        }
    }

    var titleText: String {
        switch self {
        case .card: return .payResponseCardPay
        }
    }

    var methodLogoImage: UIImage? {
        switch self {
        case .card: return nil
        }
    }

    var presentViewController: ((UIViewController, PaymentConfiguration) -> Void)? {
        switch self {
        case .card:
            return { viewController, configuration in
                PaymentCardViewController.present(with: configuration, from: viewController)
            }
        }
    }
}
