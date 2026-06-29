//
//  Scheme.swift
//  sdk
//
//  Created by Kvell on 02.07.2024.
//  Copyright © 2024 Kvell. All rights reserved.
//

import Foundation

enum Scheme: String, Codable {
    case charge = "charge"
    case auth = "auth"
}

enum IntentScheme: String, Codable {
    case single = "single"
    case dual = "dual"
}
