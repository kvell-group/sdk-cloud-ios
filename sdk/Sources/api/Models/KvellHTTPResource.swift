//
//  KvellHTTPResource.swift
//  sdk
//
//  Created by Kvell on 02.07.2021.
//  Copyright © 2021 Kvell. All rights reserved.
//

import Foundation

enum KvellHTTPResource: String {
    case charge = "payments/cards/charge"
    case auth = "payments/cards/auth"
    case post3ds = "payments/cards/post3ds"
    case configuration = "merchant/configuration"
    case binInfo = "bins/info"
    case apiIntent = "api/intent"
    case apiIntentPay = "api/intent/pay"
    
    func asUrl(apiUrl: String) -> String {
        return apiUrl.appending(self.rawValue)
    }
}
