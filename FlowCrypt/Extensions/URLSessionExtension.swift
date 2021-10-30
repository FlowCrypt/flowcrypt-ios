//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
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

private let logger = Logger.nested("URLSession")

private func toString(_ trace: Trace) -> String {
    let result = trace.result()
    if result < 1.0 {
        return "ms:\(Int(1000 * result))"
    }
    return "s:\(Int(result))"
}

extension URLSession {
    func call(_ urlRequest: URLRequest, tolerateStatus: [Int]? = nil) -> Promise<HttpRes> {
        Promise { resolve, reject in
            let trace = Trace(id: "call")
            self.dataTask(with: urlRequest) { data, response, error in
                let res = response as? HTTPURLResponse
                let status = res?.statusCode ?? GeneralConstants.Global.generalError
                let urlMethod = urlRequest.httpMethod ?? "GET"
                let urlString = urlRequest.url?.stringWithFilteredTokens ?? "??"
                let headers = urlRequest.headersWithFilteredTokens
                let message = "URLSession.call status:\(status) \(toString(trace)) \(urlMethod) \(urlString), headers: \(headers)"
                Logger.nested("URLSession").logInfo(message)

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
}

extension URLSession {
    func asyncCall(_ urlRequest: URLRequest, tolerateStatus: [Int]? = nil) async throws -> HttpRes {
        let trace = Trace(id: "asyncCall")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await self.data(for: urlRequest)
        } catch {
            throw HttpErr(
                status: GeneralConstants.Global.generalError,
                data: nil,
                error: error
            )
        }

        let res = response as? HTTPURLResponse
        let status = res?.statusCode ?? GeneralConstants.Global.generalError
        let urlMethod = urlRequest.httpMethod ?? "GET"
        let urlString = urlRequest.url?.stringWithFilteredTokens ?? "??"
        let headers = urlRequest.headersWithFilteredTokens
        let message = "URLSession.asyncCall status:\(status) \(toString(trace)) \(urlMethod) \(urlString), headers: \(headers)"
        Logger.nested("URLSession").logInfo(message)

        let validStatusCode = 200 ... 299
        let isInToleranceStatusCodes = (tolerateStatus?.contains(status) ?? false)
        guard validStatusCode ~= status || isInToleranceStatusCodes else {
            throw HttpErr(status: status, data: data, error: nil)
        }

        return HttpRes(status: status, data: data)
    }
}

enum HTTPMetod: String {
    case put = "PUT"
    case get = "GET"
    case post = "POST"
}

struct URLHeader {
    let value: String
    let httpHeaderField: String
}

extension URLRequest {
    static func urlRequest(
        with url: URL,
        method: HTTPMetod = .get,
        body: Data? = nil,
        headers: [URLHeader] = []
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        headers.forEach {
            request.addValue($0.value, forHTTPHeaderField: $0.httpHeaderField)
        }
        return request
    }

    var headersWithFilteredTokens: [String: String] {
        let headers = allHTTPHeaderFields ?? [:]
        let filteredHeaders = headers.map { ($0, $0 == "Authorization" ? "***" : $1) }
        return Dictionary(uniqueKeysWithValues: filteredHeaders)
    }
}
