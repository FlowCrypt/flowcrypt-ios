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
        return ApiError(errorDescription: object.message)
    }
}

private struct HttpError: Decodable {
    var code: Int
    var message: String
    var details: String
}
