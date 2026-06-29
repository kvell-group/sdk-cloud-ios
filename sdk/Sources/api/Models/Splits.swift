//
//  SplitsData.swift
//  sdk
//
//  Created by Kvell on 05.02.2024.
//  Copyright © 2024 Kvell. All rights reserved.
//

import Foundation

public struct Splits: Codable {
    let splits: [Split]
    
    public init(splits: [Split]) {
        self.splits = splits
    }

    enum CodingKeys: String, CodingKey {
        case splits = "Splits"
    }
}

public struct Split: Codable {
    let publicID: String
    let amount: String
    
    public init(publicID: String, amount: String) {
        self.publicID = publicID
        self.amount = amount
    }
    
    var dictionary: [String: String] {
        return ["PublicId": publicID,
                "Amount": amount]
        
    }

    enum CodingKeys: String, CodingKey {
        case publicID = "PublicId"
        case amount = "Amount"
    }
}
