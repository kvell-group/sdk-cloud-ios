//
//  Features.swift
//  sdk
//
//  Created by Kvell on 02.07.2024.
//  Copyright © 2024 Kvell. All rights reserved.
//

import Foundation

struct Features: Codable {
    let isAllowedNotSanctionedCards, isQiwi: Bool
    let isSaveCard: Int

    enum CodingKeys: String, CodingKey {
        case isAllowedNotSanctionedCards = "IsAllowedNotSanctionedCards"
        case isQiwi = "IsQiwi"
        case isSaveCard = "IsSaveCard"
    }
}
