//
//  KvellFontRegistrar.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit
import CoreText

enum KvellFontRegistrar {

    private static let didRegister: Void = registerFonts()

    static func registerIfNeeded() {
        _ = didRegister
    }

    private static func registerFonts() {
        let fontNames = ["Onest-Regular", "Onest-Medium", "Onest-SemiBold", "Onest-Bold"]

        for name in fontNames {
            guard UIFont(name: name, size: 12) == nil else { continue }
            guard let url = Bundle.mainSdk.url(forResource: name, withExtension: "ttf") else { continue }

            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            error?.release()
        }
    }
}
