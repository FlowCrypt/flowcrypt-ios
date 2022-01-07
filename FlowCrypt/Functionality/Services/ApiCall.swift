//
//  ApiCall.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 26.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import FlowCryptCommon

enum ApiCall {}

extension ApiCall {
    struct Request {
        var apiName: String
        var url: String
        var method: HTTPMethod = .get
        var body: Data?
        var headers: [URLHeader] = []
        var timeout: TimeInterval = 60.0
        var tolerateStatus: [Int]?
    }
}

extension ApiCall {
    static func call(_ request: Request) async throws -> HttpRes {
        guard let url = URL(string: request.url) else {
            throw HttpErr(
                status: -2,
                data: Data(),
                error: AppErr.unexpected("Invalid url: \(request.url)")
            )
        }

        var urlRequest = URLRequest.urlRequest(
            with: url,
            method: request.method,
            body: request.body,
            headers: request.headers
        )
        urlRequest.timeoutInterval = request.timeout

        do {
            let result = try await URLSession.shared.call(
                urlRequest,
                tolerateStatus: request.tolerateStatus
            )
            return result
        } catch {
            guard let httpError = error as? HttpErr else {
                throw error
            }
            throw ApiError.create(from: httpError, request: request)
        }
    }
}

struct ApiError: LocalizedError {
    var errorDescription: String?
    var internalError: Error?
}

extension ApiError {
    static func create(from httpError: HttpErr, request: ApiCall.Request) -> Self {
        guard
            let data = httpError.data,
            let object = try? JSONDecoder().decode(HttpError.self, from: data)
        else {
            return ApiError(
                errorDescription: httpError.error?.localizedDescription ?? "",
                internalError: httpError.error
            )
        }

        var message = "\(request.apiName) \(object.code) \(object.message)"
        message += "\n"
        message += "\(request.method) \(request.url)"

        return ApiError(errorDescription: message, internalError: httpError.error)
    }
}

private struct HttpError: Decodable {
    var code: Int
    var message: String
    var details: String
}
