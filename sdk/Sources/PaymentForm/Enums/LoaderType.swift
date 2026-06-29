//
//  LoaderType.swift
//  sdk
//
//  Created by Kvell on 14.09.2023.
//  Copyright © 2023 Kvell. All rights reserved.
//

import Foundation

public enum LoaderType: String {
    case loaderText = "Загружаем способы оплаты"
    case loadingBanks = "Загружаем список банков"
    
    public func toString() -> String {
        return self.rawValue
    }
}
