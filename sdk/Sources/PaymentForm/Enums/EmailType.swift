//
//  EmailType.swift
//  sdk
//
//  Created by Kvell on 14.09.2023.
//  Copyright © 2023 Kvell. All rights reserved.
//

import Foundation

enum EmailType: String {
    case incorrectEmail = "Некорректный e-mail"
    case receiptEmail = "E-mail для квитанции"
    case defaultEmail = "E-mail"

    func toString() -> String {
        return self.rawValue
    }
}
