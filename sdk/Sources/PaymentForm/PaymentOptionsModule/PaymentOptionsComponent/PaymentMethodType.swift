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
    case kvellPay = "KvellPay"
    case sbp = "Sbp"
    case tPay = "TPay"
    case alfaPay = "AlfaPay"
}

extension PaymentMethodType {

    var buttonTitle: String? {
        switch self {
        case .card:
            return "Банковская карта"
        default:
            return nil
        }
    }

    var buttonIcon: UIImage? {
        switch self {
        case .card: return nil
        default: return nil
        }
    }

    var additionalButtonIcon: UIImage? {
        switch self {
        case .card: return .iconCardAdditional
        default: return nil
        }
    }

    var backgroundColor: UIColor? {
        switch self {
        case .card: return .colorBlue
        default: return nil
        }
    }

    var titleText: String {
        switch self {
        case .card: return .payResponseCardPay
        default: return rawValue
        }
    }

    var methodLogoImage: UIImage? {
        switch self {
        case .card: return nil
        default: return nil
        }
    }

    var presentViewController: ((UIViewController, PaymentConfiguration) -> Void)? {
        switch self {
        case .card:
            return { viewController, configuration in
                PaymentCardViewController.present(with: configuration, from: viewController)
            }
        default:
            return nil
        }
    }
}

// MARK: - Редизайн: карточка способа оплаты на экране выбора

extension PaymentMethodType {

    /// Заголовок карточки метода на экране выбора способа оплаты.
    var pageTitle: String {
        switch self {
        case .card: return "Банковская карта"
        case .kvellPay: return "KVELL.Pay"
        case .sbp: return "Система быстрых платежей"
        case .tPay: return "T-Pay"
        case .alfaPay: return "AlfaPay"
        }
    }

    /// Подзаголовок карточки метода. nil — сабтайтл скрыт. Для комиссий (например, карты) данных пока нет — не выдумываем, nil.
    var pageSubtitle: String? {
        switch self {
        case .kvellPay: return "Оплата с привязанной карты"
        case .card, .sbp, .tPay, .alfaPay: return nil
        }
    }

    var pageLogo: UIImage? {
        switch self {
        case .card: return UIImage.named("kv_bank_cards")
        case .kvellPay: return UIImage.named("kv_kvell_pay")
        case .sbp: return UIImage.named("kv_sbp")
        case .tPay: return UIImage.named("kv_tpay")
        case .alfaPay: return UIImage.named("kv_alfapay")
        }
    }

    var pageLogoSize: CGSize {
        switch self {
        case .card: return CGSize(width: 55, height: 25)
        case .kvellPay: return CGSize(width: 35, height: 36)
        case .sbp: return CGSize(width: 55, height: 25)
        case .tPay: return CGSize(width: 55, height: 25)
        case .alfaPay: return CGSize(width: 44, height: 12)
        }
    }

    var pageStyle: PaymentMethodRowView.Style {
        switch self {
        case .kvellPay: return .kvellPay
        case .card, .sbp, .tPay, .alfaPay: return .regular
        }
    }
}
