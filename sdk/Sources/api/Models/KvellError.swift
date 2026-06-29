//
//  KvellError.swift
//  sdk
//
//  Created by Kvell on 25.09.2020.
//  Copyright © 2020 Kvell. All rights reserved.
//

import Foundation

public class KvellError: Error {
    static let defaultCardError = KvellError(message: "Unable to determine bank")
    static let networkError = KvellError(message: "Ошибка запроса")
    static let incorrectResponseJson = KvellError(message: "Некорректный ответ JSON")
    
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}
