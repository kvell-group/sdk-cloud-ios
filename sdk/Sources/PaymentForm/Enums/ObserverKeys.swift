//
//  ObserverKeys.swift
//  sdk
//
//  Created by Kvell on 16.08.2023.
//  Copyright © 2023 Kvell. All rights reserved.
//

import Foundation

enum ObserverKeys: String {
    case generalObserver = "GeneralObserver"
    case intentCardObserver = "IntentCardObserver"

    var key: NSNotification.Name {
        return NSNotification.Name(rawValue: rawValue)
    }
}
