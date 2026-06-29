import KvellNetworking
import Foundation
import UIKit

public class KvellApi {
    public static let baseURLString = "https://cloud.prod.pay-pulse.com/"
    public static let baseIntentURLString = "https://cloud.prod.pay-pulse.com/"
    private let threeDsSuccessURL = "https://cloud.prod.pay-pulse.com/success"
    private let threeDsFailURL = "https://cloud.prod.pay-pulse.com/fail"
    private let publicId: String
    private let apiSecret: String?
    private let apiUrl: String
    private let injectedDispatcher: KvellNetworkDispatcher?

    private var effectiveDispatcher: KvellNetworkDispatcher {
        injectedDispatcher ?? KvellURLSessionNetworkDispatcher.instance
    }

    private var basicAuthHeaders: [String: String] {
        let raw = "\(publicId):\(apiSecret ?? "")"
        let token = Data(raw.utf8).base64EncodedString()
        return ["Authorization": "Basic \(token)"]
    }

    init(publicId: String, apiUrl: String = baseURLString, dispatcher: KvellNetworkDispatcher? = nil, apiSecret: String? = nil) {
        self.publicId = publicId
        self.apiSecret = apiSecret
        self.injectedDispatcher = dispatcher

        if (apiUrl.isEmpty) {
            self.apiUrl = KvellApi.baseURLString
        } else {
            self.apiUrl = apiUrl
        }
    }
    
    public class func getBankInfo(cardNumber: String,
                                  completion: ((_ bankInfo: BankInfo?, _ error: KvellError?) -> ())?) {
        let cleanCardNumber = Card.cleanCreditCardNo(cardNumber)
        guard cleanCardNumber.count >= 6 else {
            completion?(nil, KvellError.init(message: "You must specify at least the first 6 digits of the card number"))
            return
        }
        
        let firstSixIndex = cleanCardNumber.index(cleanCardNumber.startIndex, offsetBy: 6)
        let firstSixDigits = String(cleanCardNumber[..<firstSixIndex])
        
        BankInfoRequest(firstSix: firstSixDigits).execute(keyDecodingStrategy: .convertToUpperCamelCase, onSuccess: { response in
            completion?(response.model, nil)
        }, onError: { error in
            if !error.localizedDescription.isEmpty  {
                completion?(nil, KvellError.init(message: error.localizedDescription))
            } else {
                completion?(nil, KvellError.defaultCardError)
            }
        })
    }
    
   public class func getBinInfoWithIntentId(cleanCardNumber: String,
                                             with configuration: PaymentConfiguration,
                                             dispatcher: KvellNetworkDispatcher = KvellURLSessionNetworkDispatcher.instance,
                                             completion: @escaping (BankInfo?, Bool?) -> Void) {
        
        guard let intentId = configuration.paymentData.intentId else {
            completion(nil, false)
            return
        }
        
        var firstSixDigits: String? = nil
        
        if cleanCardNumber.count >= 6 {
            let firstSixIndex = cleanCardNumber.index(cleanCardNumber.startIndex, offsetBy: 6)
            firstSixDigits = String(cleanCardNumber[..<firstSixIndex])
        }
        
        let queryItems = [
            "PaymentMethod": "Card",
            "Bin": firstSixDigits,
        ] as [String: String?]
        
        let request = BinInfoRequestWithIntentId(intentId: intentId, queryItems: queryItems, apiUrl: baseIntentURLString)

        request.execute(dispatcher: dispatcher) { result in
            completion(result, true)

            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)

        } onError: { error in
            print(error)
            completion(nil, false)

            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func intentPatchById(configuration: PaymentConfiguration,
                                      patches: [[String: Any]],
                                      dispatcher: KvellNetworkDispatcher = KvellURLSessionNetworkDispatcher.instance,
                                      completion: @escaping (PaymentIntentResponse?) -> Void) {
        guard let intentId = configuration.paymentData.intentId else {
            print("PATCH: intentId отсутствует")
            completion(nil)
            return
        }
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: patches, options: []) else {
            print("PATCH: не удалось сериализовать JSON")
            completion(nil)
            return
        }
        
        var headers: [String: String] = [
            "Content-Type": "application/json-patch+json"
        ]
        
        if let secret = configuration.paymentData.secret {
            headers["Secret"] = secret
        }
        
        let request = IntentPatchById(
            patchBody: bodyData,
            intentId: intentId,
            apiUrl: baseIntentURLString,
            headers: headers
        )
        
        print("PATCH: отправка запроса")
        print("PATCH: \(patches)")
        
        request.execute(dispatcher: dispatcher) { result in

            print("PATCH: ответ получен")

            completion(result)

            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)

        } onError: { error in

            print("PATCH: ошибка: \(error.localizedDescription)")
            completion(nil)

            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func createIntent(with configuration: PaymentConfiguration,
                                   paymentMethodSequence: [String],
                                   dispatcher: KvellNetworkDispatcher = KvellURLSessionNetworkDispatcher.instance,
                                   completion handler: @escaping (PaymentIntentResponse?) -> Void) {
        
        let publicId = configuration.publicId
        let currency = configuration.paymentData.currency
        let sсheme: IntentScheme = configuration.useDualMessagePayment ? .dual : .single
        let type = "Default"
        let scenario = "7"
        let amount = configuration.paymentData.amount
        let accountId = configuration.paymentData.accountId
        let email = configuration.paymentData.email
        let paymentUrl = "kvell://sdk.pay-pulse.example"
        let payer = configuration.paymentData.payer
        let recurrent = configuration.paymentData.recurrent?.toDictionary()
        let receipt = configuration.paymentData.receipt
        let successRedirectUrl = configuration.successRedirectUrl
        let failRedirectUrl = configuration.failRedirectUrl
        let invoiceId = configuration.paymentData.invoiceId
        let description = configuration.paymentData.description
        
        let metadata: [String: Any]? = {
            if let jsonString = configuration.paymentData.jsonData,
               let data = jsonString.data(using: .utf8) {
                return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            }
            return nil
        }()
        
        let params: [String: Any?] = [
            "publicTerminalId": publicId,
            "currency": currency,
            "paymentSchema": sсheme.rawValue,
            "culture": "RU-ru",
            "type": type,
            "scenario": scenario,
            "amount": amount,
            "paymentUrl": paymentUrl,
            "receiptEmail": email,
            "externalId": invoiceId,
            "description": description,
            "userInfo": [
                "accountId": accountId,
                "firstName": payer?.firstName,
                "lastName": payer?.lastName,
                "middleName": payer?.middleName,
                "address": payer?.address,
                "street": payer?.street,
                "city": payer?.city,
                "country": payer?.country,
                "phone": payer?.phone,
                "postcode": payer?.postcode
            ],
            "paymentMethodSequence": paymentMethodSequence,
            "recurrent": recurrent,
            "receipt": receipt,
            "metadata": metadata,
            "successRedirectUrl": successRedirectUrl,
            "failRedirectUrl":  failRedirectUrl
            
        ] as [String : Any?]
        
        let request = CreateIntentRequest(params: params,
                                          apiUrl: baseIntentURLString)
        request.execute(dispatcher: dispatcher) { result in
            handler(result)
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
        } onError: { error in
            print("createIntent error:", error.localizedDescription)
            handler(nil)
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public func intentApiPay(cardCryptogram: String,
                                   with configuration: PaymentConfiguration,
                                   completion: @escaping (Int?, PaymentIntentResponse?) -> Void) {
        
        let params = ["Id": configuration.paymentData.intentId,
                      "PaymentMethod": "Card",
                      "Cryptogram": cardCryptogram]
        
        print(cardCryptogram)
        print(params)
        
        let request = CreateIntentApiPayRequest(params: params,
                                                apiUrl: KvellApi.baseIntentURLString)
        
        request.executeWithStatusCode(dispatcher: effectiveDispatcher) { statusCode, result in
            print("Status Code: \(statusCode), Result: \(String(describing: result))")
            completion(statusCode, result)

            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)

        } onError: { statusCode, error in
            completion(statusCode, nil)

            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public func charge(amount: String,
                       currency: String,
                       ipAddress: String,
                       cardCryptogramPacket: String,
                       name: String? = nil,
                       invoiceId: String? = nil,
                       description: String? = nil,
                       accountId: String? = nil,
                       email: String? = nil,
                       payer: [String: Any?]? = nil,
                       jsonData: String? = nil,
                       paymentUrl: String = "kvell://sdk.pay-pulse.com",
                       completion: @escaping (Int?, CardsResponse?) -> Void) {
        let params: [String: Any?] = [
            "Amount": amount,
            "Currency": currency,
            "IpAddress": ipAddress,
            "CardCryptogramPacket": cardCryptogramPacket,
            "Name": name,
            "PaymentUrl": paymentUrl,
            "InvoiceId": invoiceId,
            "Description": description,
            "AccountId": accountId,
            "Email": email,
            "Payer": payer,
            "JsonData": jsonData
        ]
        let request = CardsChargeRequest(params: params, headers: basicAuthHeaders, apiUrl: apiUrl)
        request.executeWithStatusCode(dispatcher: effectiveDispatcher) { statusCode, result in
            completion(statusCode, result)
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
        } onError: { statusCode, _ in
            completion(statusCode, nil)
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }

    public func post3ds(transactionId: Int,
                        paRes: String,
                        completion: @escaping (CardsResponse?) -> Void) {
        let params: [String: Any?] = [
            "TransactionId": transactionId,
            "PaRes": paRes
        ]
        let request = CardsPost3dsRequest(params: params, headers: basicAuthHeaders, apiUrl: apiUrl)
        request.execute(dispatcher: effectiveDispatcher) { result in
            completion(result)
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
        } onError: { _ in
            completion(nil)
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }

    class func loadImage(url string: String,
                         completion: @escaping (UIImage?) -> Void) {
        
        guard let url = URL(string: string) else { return completion(nil) }
        
        let task = URLSession.shared.dataTask(with: .init(url: url)) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return completion(nil) }
            completion(image)
        }
        
        task.resume()
    }
}

public typealias KvellRequestCompletion<T> = (_ response: T?, _ error: Error?) -> Void

private struct KvellCodingKey: CodingKey {
    var stringValue: String
    
    init(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int? {
        return nil
    }
    
    init?(intValue: Int) {
        return nil
    }
}

extension JSONDecoder.KeyDecodingStrategy {
    static var convertToUpperCamelCase: JSONDecoder.KeyDecodingStrategy {
        return .custom({ keys -> CodingKey in
            let lastKey = keys.last!
            if lastKey.intValue != nil {
                return lastKey
            }
            
            let firstLetter = lastKey.stringValue.prefix(1).lowercased()
            let modifiedKey = firstLetter + lastKey.stringValue.dropFirst()
            return KvellCodingKey(stringValue: modifiedKey)
        })
    }
}

extension KvellApi {
    public class func getPublicKey(dispatcher: KvellNetworkDispatcher = KvellURLSessionNetworkDispatcher.instance,
                                   completion: @escaping (PublicKeyResponse?, Error?) -> Void) {
        let kvellRequest = KvellRequest(
            path: baseURLString + "payments/publickey",
            method: .get,
            params: [:],
            headers: [:],
            body: nil
        )
        dispatcher.dispatch(
            request: kvellRequest,
            onSuccess: { data in
                do {
                    let response = try JSONDecoder().decode(PublicKeyResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(response, nil)
                        LoggerService.shared.logApiRequest(method: kvellRequest.method.rawValue, url: kvellRequest.path, success: true)
                    }
                } catch {
                    DispatchQueue.main.async {
                        LoggerService.shared.logApiRequest(method: kvellRequest.method.rawValue, url: kvellRequest.path, success: false)
                        completion(nil, error)
                    }
                }
            },
            onError: { error in
                DispatchQueue.main.async {
                    LoggerService.shared.logApiRequest(method: kvellRequest.method.rawValue, url: kvellRequest.path, success: false)
                    completion(nil, error)
                }
            },
            onRedirect: nil
        )
    }
    
    public class func post<T: Encodable>(to endpoint: String, body: [T], completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let url = URL(string: endpoint) else {
            completion?(.failure(KvellError.networkError))
            return
        }
        do {
            let data = try JSONEncoder().encode(body)
            if let json = String(data: data, encoding: .utf8) {
                print("------------>>>>> Analytics JSON payload:\n\(json)")
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
            
            URLSession.shared.dataTask(with: request) { _, response, error in
                if let http = response as? HTTPURLResponse {
                    print("Analytics sent — Status:", http.statusCode)
                    completion?(.success(()))
                } else if let error = error {
                    print("Analytics send error:", error)
                    completion?(.failure(error))
                }
            }.resume()
        } catch {
            print("Encoding error:", error)
            completion?(.failure(error))
        }
    }
}
