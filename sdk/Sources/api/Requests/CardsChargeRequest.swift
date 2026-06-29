//
//  CardsChargeRequest.swift
//  Kvell
//

import KvellNetworking

final class CardsChargeRequest: BaseRequest, KvellRequestType {
    typealias ResponseType = CardsResponse
    var data: KvellRequest {
        return KvellRequest(path: KvellHTTPResource.charge.asUrl(apiUrl: apiUrl), method: .post, params: params, headers: headers)
    }
}

final class CardsPost3dsRequest: BaseRequest, KvellRequestType {
    typealias ResponseType = CardsResponse
    var data: KvellRequest {
        return KvellRequest(path: KvellHTTPResource.post3ds.asUrl(apiUrl: apiUrl), method: .post, params: params, headers: headers)
    }
}
