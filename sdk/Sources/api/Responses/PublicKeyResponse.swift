//
//  PublicKeyData.swift
//  Kvell
//
//  Created by Kvell on 31.05.2023.
//

import Foundation

public struct PublicKeyResponse: Codable {
    let Pem: String?
    let Version: Int?

    enum CodingKeys: String, CodingKey {
        case Pem = "pem"
        case Version = "version"
    }
}
