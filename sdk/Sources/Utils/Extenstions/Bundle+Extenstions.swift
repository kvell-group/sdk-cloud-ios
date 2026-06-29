//
//  Bundle+Extenstions.swift
//  sdk
//
//  Created by Kvell on 16.09.2020.
//  Copyright © 2020 Kvell. All rights reserved.
//

import UIKit

extension Bundle {

    class var mainSdk: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        let fallbackBundle = Bundle(for: PaymentForm.self)
        
        if let bundleUrl = fallbackBundle.url(forResource: "KvellSDK", withExtension: "bundle"),
           let podBundle = Bundle(url: bundleUrl) {
            return podBundle
        } else {
            return fallbackBundle
        }
        #endif
    }
    
    class var cocoapods: Bundle? {
        return Bundle(identifier: "org.cocoapods.Kvell")
    }
}


