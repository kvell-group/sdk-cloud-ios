//
//  CardsResponse.swift
//  sdk
//

import Foundation

public struct CardsResponse: Codable {
    public private(set) var Success: Bool?
    public private(set) var Message: String?
    public private(set) var Model: CardsResponseModel?
}

public struct CardsResponseModel: Codable {
    public private(set) var TransactionId: Int
    public private(set) var PaReq: String?
    public private(set) var AcsUrl: String?
    public private(set) var ThreeDsCallbackId: String?
    public private(set) var ThreeDsSessionData: String?
    public private(set) var IFrameIsAllowed: Bool?
    public private(set) var GoReq: String?
    public private(set) var Status: String?
    public private(set) var StatusCode: Int?
    public private(set) var ReasonCode: Int?
    public private(set) var CardHolderMessage: String?
}
