//
//  ConfigurationRequest.swift
//  sdk
//
//  Created by Kvell on 15.11.2023.
//  Copyright © 2023 Kvell. All rights reserved.
//

import Foundation
import KvellNetworking

final class ConfigurationRequest: BaseRequest, KvellRequestType {
    typealias ResponseType = MerchantConfigurationResponse
    var data: KvellRequest {
        let path = KvellHTTPResource.configuration.asUrl(apiUrl: apiUrl)
       
        guard var component = URLComponents(string: path) else { return KvellRequest(path: path, headers: headers) }
       
        if !queryItems.isEmpty {
            let items = queryItems.compactMap { return URLQueryItem(name: $0, value: $1) }
            component.queryItems = items
        }
        
        guard let url = component.url else { return KvellRequest(path: path, headers: headers) }
        let fullPath = url.absoluteString
        
        return KvellRequest(path: fullPath, headers: headers)
    }
}
