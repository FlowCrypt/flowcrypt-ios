//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

public struct HttpRes {
    public let status: Int
    public let data: Data

    public init(status: Int, data: Data) {
        self.status = status
        self.data = data
    }
}

public struct HttpErr: Error {
    public let status: Int
    public let data: Data?
    public let error: Error?

    public init(status: Int, data: Data?, error: Error?) {
        self.status = status
        self.data = data
        self.error = error
    }
}

public enum HTTPMethod: String {
    case put = "PUT"
    case get = "GET"
    case post = "POST"
}

public extension URLSession {
    static let generalError = -1

    func call(_ urlRequest: URLRequest, tolerateStatus: [Int]? = nil, delegate: URLSessionTaskDelegate? = nil) async throws -> HttpRes {
        let trace = Trace(id: "call")

        var data: Data?
        var response: URLResponse?
        var requestError: Error?

        do {
            (data, response) = try await self.data(for: urlRequest, delegate: delegate)
        } catch {
            requestError = error
        }

        let res = response as? HTTPURLResponse
        let status = res?.statusCode ?? Self.generalError
        let urlMethod = urlRequest.httpMethod ?? "GET"
        let urlString = urlRequest.url?.stringWithFilteredTokens ?? "??"
        let headers = urlRequest.headersWithFilteredTokens
        let message = "URLSession.call status:\(status) \(toString(trace)) \(urlMethod) \(urlString), headers: \(headers)"
        Logger.nested("URLSession").logInfo(message)

        let validStatusCode = 200 ... 299
        let isInToleranceStatusCodes = (tolerateStatus?.contains(status) ?? false)
        let isCodeValid = validStatusCode ~= status || isInToleranceStatusCodes
        let isValidResponse = requestError == nil && isCodeValid
        if let data, isValidResponse {
            return HttpRes(status: status, data: data)
        } else {
            throw HttpErr(status: status, data: data, error: requestError)
        }
    }

    private func toString(_ trace: Trace) -> String {
        let result = trace.result()
        if result < 1.0 {
            return "ms:\(Int(1000 * result))"
        }
        return "s:\(Int(result))"
    }
}

public struct URLHeader {
    public init(value: String, httpHeaderField: String) {
        self.value = value
        self.httpHeaderField = httpHeaderField
    }

    let value: String
    let httpHeaderField: String
}

public extension URLRequest {
    static func urlRequest(
        with url: URL,
        method: HTTPMethod = .get,
        body: Data? = nil,
        headers: [URLHeader] = []
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.httpHeaderField)
        }
        return request
    }

    var headersWithFilteredTokens: [String: String] {
        let headers = allHTTPHeaderFields ?? [:]
        let filteredHeaders = headers.map { ($0, $0 == "Authorization" ? "***" : $1) }
        return Dictionary(uniqueKeysWithValues: filteredHeaders)
    }
}
