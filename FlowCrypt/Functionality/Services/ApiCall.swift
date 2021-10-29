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
    struct Endpoint {
        var name: String
        var url: String
        var method: HTTPMetod = .get
        var body: Data?
        var headers: [URLHeader] = []
        var timeout: TimeInterval = 60.0
        var tolerateStatus: [Int]?
    }
}

extension ApiCall {
    static func call(_ endpoint: Endpoint) -> Promise<HttpRes> {
        Promise { () -> HttpRes in
            guard let url = URL(string: endpoint.url) else {
                throw HttpErr(
                    status: -2,
                    data: Data(),
                    error: AppErr.unexpected("Invalid url: \(endpoint.url)")
                )
            }

            var request = URLRequest.urlRequest(
                with: url,
                method: endpoint.method,
                body: endpoint.body,
                headers: endpoint.headers
            )
            request.timeoutInterval = endpoint.timeout

            do {
                let result = try awaitPromise(URLSession.shared.call(
                    request,
                    tolerateStatus: endpoint.tolerateStatus)
                )
                return result
            } catch {
                guard let httpError = error as? HttpErr else {
                    throw error
                }
                throw ApiError.create(from: httpError, endpoint: endpoint)
            }
        }
    }
}

extension ApiCall {
    static func asyncCall(_ endpoint: Endpoint) async throws -> HttpRes {
        guard let url = URL(string: endpoint.url) else {
            throw HttpErr(
                status: -2,
                data: Data(),
                error: AppErr.unexpected("Invalid url: \(endpoint.url)")
            )
        }

        var request = URLRequest.urlRequest(
            with: url,
            method: endpoint.method,
            body: endpoint.body,
            headers: endpoint.headers
        )
        request.timeoutInterval = endpoint.timeout

        do {
            let result = try await URLSession.shared.asyncCall(
                request,
                tolerateStatus: endpoint.tolerateStatus
            )
            return result
        } catch {
            guard let httpError = error as? HttpErr else {
                throw error
            }
            throw ApiError.create(from: httpError, endpoint: endpoint)
        }
    }
}

struct ApiError: LocalizedError {
    var errorDescription: String?
}

extension ApiError {
    static func create(from httpError: HttpErr, endpoint: ApiCall.Endpoint) -> Self {
        guard
            let data = httpError.data,
            let object = try? JSONDecoder().decode(HttpError.self, from: data)
        else {
            return ApiError(errorDescription: httpError.error?.localizedDescription ?? "")
        }

        var message = "\(endpoint.name) \(object.code) \(object.message)"
        message += "\n"
        message += "\(endpoint.method) \(endpoint.url)"
        return ApiError(errorDescription: message)
    }
}

private struct HttpError: Decodable {
    var code: Int
    var message: String
    var details: String
}
