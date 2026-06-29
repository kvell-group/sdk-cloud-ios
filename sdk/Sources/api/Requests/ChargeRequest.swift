//
//  ChargeRequest.swift
//  Kvell
//
//  Created by Kvell on 01.07.2021.
//

import KvellNetworking

final class ChargeRequest: BaseRequest, KvellRequestType {
    typealias ResponseType = TransactionResponse
    var data: KvellRequest {
        return KvellRequest(path: KvellHTTPResource.charge.asUrl(apiUrl: apiUrl), method: .post, params: params, headers: headers)
    }
}
