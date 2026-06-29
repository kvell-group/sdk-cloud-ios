//
//  BinInfoRequest.swift
//  sdk
//
//  Created by Kvell on 05.02.2024.
//  Copyright © 2024 Kvell. All rights reserved.
//

import Foundation
import KvellNetworking

final class BinInfoRequestWithIntentId: BaseRequest, KvellRequestType {
    typealias ResponseType = BankInfo

    private let intentId: String

    init(intentId: String, queryItems: [String: String?], apiUrl: String) {
        self.intentId = intentId
        super.init(queryItems: queryItems, apiUrl: apiUrl)
    }

    var data: KvellRequest {
        let path = "\(apiUrl)api/intent/\(intentId)/bininfo"

        guard var component = URLComponents(string: path) else {
            return KvellRequest(path: path, method: .get, headers: headers)
        }

        if !queryItems.isEmpty {
            let items = queryItems.compactMap { URLQueryItem(name: $0, value: $1) }
            component.queryItems = items
        }

        guard let url = component.url else {
            return KvellRequest(path: path, method: .get, headers: headers)
        }

        let fullPath = url.absoluteString

        return KvellRequest(path: fullPath, method: .get, headers: headers)
    }
}
