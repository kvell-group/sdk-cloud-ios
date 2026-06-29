//
//  BankInfoRequest.swift
//  Kvell
//
//  Created by Kvell on 01.07.2021.
//

import KvellNetworking

final class BankInfoRequest: BaseRequest, KvellRequestType {
    private let firstSix: String
    init(firstSix: String) {
        self.firstSix = firstSix
    }
    typealias ResponseType = BankInfoResponse
    var data: KvellRequest {
        return KvellRequest(path: "https://api.pay-pulse.example/bins/info/\(firstSix)", method: .get)
    }
}
