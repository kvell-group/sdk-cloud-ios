//
//  BankInfoResponse.swift
//  sdk
//
//  Created by Kvell on 29.09.2020.
//  Copyright © 2020 Kvell. All rights reserved.
//

public struct BankInfoResponse: Codable {
    let success: Bool?
    let message: String?
    let model: BankInfo?
    
    enum CodingKeys: String, CodingKey {
        case model = "Model"
        case success = "Success"
        case message = "Message"
    }
}
