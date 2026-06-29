//
//  KvellError.swift
//  sdk
//
//  Created by Kvell on 25.09.2020.
//  Copyright © 2020 Kvell. All rights reserved.
//

public class KvellError: Error {
    public static let defaultCardError = KvellError.init(message: "Unable to determine bank")
    public static let networkError = KvellError(message: "Ошибка запроса")
    public static let incorrectResponseJson = KvellError(message: "Некорректный ответ JSON")
    public static let parseError = KvellError.init(message: "Не удалось получить ответ")
    
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
    
    public class func invalidURL(url: String?) -> KvellError {
        return KvellError.init(message: "Invalid url: \(String(describing: url))")
    }
}
