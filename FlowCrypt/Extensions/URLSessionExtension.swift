//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
import Foundation

struct HttpRes {
    let status: Int
    let data: Data
}

struct HttpErr: Error {
    let status: Int
    let data: Data?
    let error: Error?
}

private func toString(_ trace: Trace) -> String {
    let result = trace.result()
    if result < 1.0 {
        return "ms:\(Int(1000 * result))"
    }
    return "s:\(Int(result))"
}

extension URLSession {
    func call(_ urlRequest: URLRequest, tolerateStatus: [Int]? = nil) async throws -> HttpRes {
        let trace = Trace(id: "call")

        var data: Data?
        var response: URLResponse?
        var requestError: Error?
        do {
            (data, response) = try await self.data(for: urlRequest)
        } catch {
            requestError = error
        }

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
        let isValidResponse = requestError == nil && isCodeValid
        if let data = data, isValidResponse {
            return HttpRes(status: status, data: data)
        } else {
            throw HttpErr(status: status, data: data, error: requestError)
        }
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
