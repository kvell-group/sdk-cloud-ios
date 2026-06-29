//
//  AuthRequest.swift
//  Kvell
//
//  Created by Kvell on 01.07.2021.
//

import KvellNetworking

final class AuthRequest: BaseRequest, KvellRequestType {
    typealias ResponseType = TransactionResponse
    var data: KvellRequest {
        return KvellRequest(path: KvellHTTPResource.auth.asUrl(apiUrl: apiUrl), method: .post, params: params, headers: headers)
    }
}
