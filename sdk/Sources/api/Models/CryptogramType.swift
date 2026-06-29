//
//  CryptogramType.swift
//  Kvell
//
//  Created by Kvell on 05.06.2023.
//

import Foundation

struct CryptogramType: Codable {
    let `Type`: String
    let CardInfo: CardInfo
    let KeyVersion: String
    let Value: String
    let Format: Int
    let BrowserInfoBase64: String?

    init(CardInfo: CardInfo, version: String, value: String, browserInfoBase64: String?) {
        self.`Type` = "CloudCard"
        self.CardInfo = CardInfo
        self.KeyVersion = version
        self.Value = value
        self.Format = 1
        self.BrowserInfoBase64 = browserInfoBase64
    }
}

struct CardInfo: Codable {
    let FirstSixDigits: String
    let LastFourDigits: String
    let ExpDateMonth: String
    let ExpDateYear: String
}

struct BrowserInfo: Codable {
    let AcceptHeader: String
    let JavaEnabled: Bool
    let JavaScriptEnabled: Bool
    let Language: String
    let ColorDepth: String
    let Height: String
    let Width: String
    let TimeZone: String
    let UserAgent: String
}
