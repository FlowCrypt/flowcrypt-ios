//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises
import FlowCryptCommon

struct HttpRes {
    let status: Int
    let data: Data
}

struct HttpErr: Error {
    let status: Int
    let data: Data?
    let error: Error?
}

extension URLSession {
    func call(_ urlRequest: URLRequest, tolerateStatus: [Int]? = nil) -> Promise<HttpRes> {
        return Promise { resolve, reject in
            let start = DispatchTime.now()
            self.dataTask(with: urlRequest) { data, response, error in
                let res = response as? HTTPURLResponse
                let status = res?.statusCode ?? GeneralConstants.Global.generalError
                print("URLSession.call status:\(status) ms:\(start.millisecondsSince) \(urlRequest.httpMethod ?? "GET") \(urlRequest.url?.absoluteString ?? "??")")
                let validStatusCode = 200 ... 299
                let isInToleranceStatusCodes = (tolerateStatus?.contains(status) ?? false)
                let isCodeValid = validStatusCode ~= status || isInToleranceStatusCodes
                let isValidResponse = error == nil && isCodeValid
                if let data = data, isValidResponse {
                    resolve(HttpRes(status: status, data: data))
                } else {
                    reject(HttpErr(status: status, data: data, error: error))
                }
            }.resume()
        }
    }

    func call(_ urlStr: String, tolerateStatus: [Int]? = nil) -> Promise<HttpRes> {
        return Promise { () -> HttpRes in
            let url = URL(string: urlStr)
            guard url != nil else {
                throw HttpErr(status: -2, data: Data(), error: AppErr.value("Invalid url: \(urlStr)"))
            }
            return try await(self.call(URLRequest(url: url!), tolerateStatus: tolerateStatus))
        }
    }
}
