//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

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
                let status = res?.statusCode ?? Constants.Global.generalError

                print("URLSession.call status:\(status) ms:\(start.millisecondsSince) \(urlRequest.url?.absoluteString ?? "??")")

                let validStatusCode = 200...299

                let isInToleranceStatusCodes = (tolerateStatus?.contains(status) ?? false)
                let isCodeVaild = validStatusCode ~= status || isInToleranceStatusCodes
                let isValidResonse = error == nil && isCodeVaild

                if let data = data, isValidResonse {
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
