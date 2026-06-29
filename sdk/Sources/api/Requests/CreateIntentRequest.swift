//
//  CreateIntentRequest.swift
//  sdk
//
//  Created by Kvell on 16.09.2025.
//  Copyright © 2025 Kvell. All rights reserved.
//

import Foundation
import KvellNetworking

final class CreateIntentRequest: BaseRequest, KvellRequestType {
    typealias ResponseType = PaymentIntentResponse
    var data: KvellRequest {
        let path = KvellHTTPResource.apiIntent.asUrl(apiUrl: apiUrl)
       
        guard var component = URLComponents(string: path) else { return KvellRequest(path: path, method: .post, params: params, headers: headers) }
       
        if !queryItems.isEmpty {
            let items = queryItems.compactMap { return URLQueryItem(name: $0, value: $1) }
            component.queryItems = items
        }
        
        guard let url = component.url else { return KvellRequest(path: path, method: .post, params: params, headers: headers) }
        let fullPath = url.absoluteString
        print(fullPath)
        
        return KvellRequest(path: fullPath, method: .post, params: params, headers: headers)
    }
}
