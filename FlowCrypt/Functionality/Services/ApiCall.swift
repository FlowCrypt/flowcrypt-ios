//
//  ApiCall.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 26.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises

enum ApiCall {}

extension ApiCall {
    static func call(_ urlRequest: URLRequest, tolerateStatus: [Int]? = nil) -> Promise<HttpRes> {
        do {
            let result = try awaitPromise(URLSession.shared.call(urlRequest, tolerateStatus: tolerateStatus))
            return Promise(result)
        } catch {
            guard let httpError = error as? HttpErr else {
                return Promise(error)
            }
            return Promise(ApiError.create(from: httpError))
        }
    }

    static func call(_ urlStr: String, tolerateStatus: [Int]? = nil) -> Promise<HttpRes> {
        Promise { () -> HttpRes in
            let url = URL(string: urlStr)
            guard url != nil else {
                throw HttpErr(status: -2, data: Data(), error: AppErr.unexpected("Invalid url: \(urlStr)"))
            }
            return try awaitPromise(call(URLRequest(url: url!), tolerateStatus: tolerateStatus))
        }
    }
}

extension ApiCall {
    static func asyncCall(_ urlRequest: URLRequest, tolerateStatus: [Int]? = nil) async throws -> HttpRes {
        do {
            let result = try await URLSession.shared.asyncCall(urlRequest, tolerateStatus: tolerateStatus)
            return result
        } catch {
            guard let httpError = error as? HttpErr else {
                throw error
            }
            throw ApiError.create(from: httpError)
        }
    }

    static func asyncCall(_ urlStr: String, tolerateStatus: [Int]? = nil, timeout: TimeInterval = 60) async throws -> HttpRes {
        guard let url = URL(string: urlStr) else {
            throw HttpErr(status: -2, data: Data(), error: AppErr.unexpected("Invalid url: \(urlStr)"))
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        return try await asyncCall(request, tolerateStatus: tolerateStatus)
    }
}

struct ApiError: LocalizedError {
    var errorDescription: String?
}

extension ApiError {
    static func create(from httpError: HttpErr) -> Self {
        guard
            let data = httpError.data,
            let object = try? JSONDecoder().decode(HttpError.self, from: data)
        else {
            return ApiError(errorDescription: httpError.error?.localizedDescription ?? "")
        }
        return ApiError(errorDescription: "Status code \(object.code), message: \(object.message)")
    }
}

private struct HttpError: Decodable {
    var code: Int
    var message: String
    var details: String
}
