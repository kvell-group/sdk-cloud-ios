//
//  IntentPatchById.swift
//  sdk
//
//  Created by Kvell on 16.09.2025.
//  Copyright © 2025 Kvell. All rights reserved.
//

import Foundation
import KvellNetworking

final class IntentPatchById: BaseRequest, KvellRequestType {
    typealias ResponseType = PaymentIntentResponse

    private let intentId: String

    init(patchBody: Data, intentId: String, apiUrl: String, headers: [String: String]) {
        self.intentId = intentId
        super.init(
            queryItems: [:],
            headers: headers,
            apiUrl: apiUrl,
            body: patchBody
        )
    }

    var data: KvellRequest {
        let fullUrl = "\(apiUrl)api/intent/\(intentId)"
        return KvellRequest(
            path: fullUrl,
            method: .patch,
            headers: headers,
            body: body
        )
    }
}
