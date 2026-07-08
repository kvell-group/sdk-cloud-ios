//
//  PaymentViewModel.swift
//  demo
//
//  Created by Kvell on 27.06.2023.
//  Copyright © 2023 Kvell. All rights reserved.
//

import UIKit
import Foundation
import Kvell

enum PaymentViewModelType: Codable {
    case publicId
    case apiUrl
    case apiSecret
    case amount
    case currency
    case invoiceId
    case description
    case accountId
    case email
    case payerFirstName
    case payerLastName
    case payerMiddleName
    case payerBirthday
    case payerAddress
    case payerStreet
    case payerCity
    case payerCountry
    case payerPhone
    case payerPostcode
    case jsonData
    
    //title
    var title: String {
        switch self {
        case .publicId: return "PublicId:"
        case .apiUrl: return "Api URL:"
        case .apiSecret: return "ApiSecret (Dev backend):"
        case .amount: return "Amount:"
        case .currency: return "Currency (Optional):"
        case .invoiceId: return "InvoiceId (Optional):"
        case .description: return "Description (Optional):"
        case .accountId: return "AccountId (Optional):"
        case .email: return "Email (Optional):"
        case .payerFirstName: return "Payer.FirstName (Optional):"
        case .payerLastName: return "Payer.LastName (Optional):"
        case .payerMiddleName: return "Payer.MiddleName (Optional):"
        case .payerBirthday: return "Payer.Birthday (Optional):"
        case .payerAddress: return "Payer.Address (Optional):"
        case .payerStreet: return "Payer.Street (Optional):"
        case .payerCity: return "Payer.City (Optional):"
        case .payerCountry: return "Payer.Country (Optional):"
        case .payerPhone: return "Payer.Phone (Optional):"
        case .payerPostcode: return "Payer.Postcode (Optional):"
        case .jsonData: return "JsonData (Optional):"
        }
    }
    
    //text
    var `default`: String {
        switch self {
        // Креды тестового терминала дев-окружения — рабочие дефолты демо.
        case .publicId: return "d55c38ac-d442-47e9-b7cd-35a03320281b"
        case .apiUrl: return KvellApi.baseURLString
        case .apiSecret: return "45faa630-ea0b-49cb-a7e0-744c1e5a41e3"
        case .amount: return "100"
        case .currency: return "RUB"
        case .invoiceId: return "AB1234"
        case .description: return "Оплата тестового заказа в демо-приложении Kvell"
        case .accountId: return "AB12"
        case .email: return "test@kvell.io"
        case .payerFirstName: return "Vasya"
        case .payerLastName: return  "Ivanov"
        case .payerMiddleName: return "Semionovich"
        case .payerBirthday: return "1955-02-24"
        case .payerAddress: return "home 8, room 36"
        case .payerStreet: return "Lenina"
        case .payerCity: return "Moscow"
        case .payerCountry: return "RU-ru"
        case .payerPhone: return "89991234567"
        case .payerPostcode: return "123456"
        case .jsonData: return "{\"name\": \"Ivan\"}"
        }
    }
    
    //placeholder
    var placeholder: String {
        switch self {
        case .apiUrl: return "URL тестового сервера"
        case .apiSecret: return "ApiSecret терминала (Basic-auth)"
        default: return "Введите текст"
        }
    }
}

struct PaymentViewModel: Codable {
    private static var key: String { return "PaymentViewModel_Key"}
    
    let type: PaymentViewModelType
    var text: String?
    
    init(_ type: PaymentViewModelType) {
        self.type = type
        self.text = type.default
    }
    
    private static let allTypes: [PaymentViewModelType] = [
        .publicId,
        .apiUrl,
        .apiSecret,
        .amount,
        .currency,
        .invoiceId,
        .description,
        .accountId,
        .email,
        .payerFirstName,
        .payerLastName,
        .payerMiddleName,
        .payerBirthday,
        .payerAddress,
        .payerStreet,
        .payerCity,
        .payerCountry,
        .payerPhone,
        .payerPostcode,
        .jsonData
    ]

    static func getViewModel() -> [PaymentViewModel] {
        let saved: [PaymentViewModel]
        if let data = UserDefaults.standard.data(forKey: PaymentViewModel.key),
           let array = try? JSONDecoder().decode([PaymentViewModel].self, from: data) {
            saved = array
        } else {
            saved = []
        }

        // Сохранённый в UserDefaults список может не содержать полей, добавленных
        // в новых версиях демо, — дополняем его до полного набора.
        // Устаревшие дефолты прошлых версий сбрасываем на актуальные.
        let outdatedDefaults = ["A basket of oranges"]
        return allTypes.map { type in
            guard let savedModel = saved.first(where: { $0.type == type }) else {
                return PaymentViewModel(type)
            }
            if let text = savedModel.text, outdatedDefaults.contains(text) {
                return PaymentViewModel(type)
            }
            return savedModel
        }
    }
    
    static func saving(_ model: [PaymentViewModel]) {
        let data = try? JSONEncoder().encode(model)
        UserDefaults.standard.set(data, forKey: PaymentViewModel.key)
        UserDefaults.standard.synchronize()
    }
}

