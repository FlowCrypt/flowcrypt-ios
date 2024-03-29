//
//  ApiCall.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 26.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon

final class ApiCall: NSObject {

    private var progressHandler: ((Float) -> Void)?
    static let shared = ApiCall()

    func call(_ request: Request) async throws -> HttpRes {
        progressHandler = request.progressHandler
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
            return try await URLSession.shared.call(
                urlRequest,
                tolerateStatus: request.tolerateStatus,
                delegate: self
            )
        } catch {
            guard let httpError = error as? HttpErr else {
                throw error
            }

            throw ApiError.create(from: httpError, request: request)
        }
    }
}

extension ApiCall {
    struct Request {
        var apiName: String
        var url: String
        var method: HTTPMethod = .get
        var body: Data?
        var headers: [URLHeader] = []
        var timeout: TimeInterval = 60.0
        var tolerateStatus: [Int]?
        var progressHandler: ((Float) -> Void)?
    }
}

extension ApiCall.Request {
    var description: String { [method.rawValue, url].joined(separator: " ") }
}

extension ApiCall: URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        progressHandler?(Float(task.progress.fractionCompleted))
    }
}

struct ApiError: LocalizedError {
    var errorDescription: String?
    var internalError: Error?
}

extension ApiError {
    static func create(from httpError: HttpErr, request: ApiCall.Request) -> Self {
        guard let data = httpError.data else {
            let errorMessage = httpError.error?.localizedDescription ?? ""
            return ApiError(
                errorDescription: errorMessage + "\n\n" + request.description,
                internalError: httpError.error
            )
        }

        guard let object = try? JSONDecoder().decode(HttpError.self, from: data) else {
            let errorDescription = httpError.error?.localizedDescription
                ?? String(data: data, encoding: .utf8)
                ?? "missing error description"

            return ApiError(
                errorDescription: errorDescription,
                internalError: httpError.error
            )
        }

        var message = "\(request.apiName) \(object.code) \(object.message)"
        message += "\n"
        message += request.description

        return ApiError(errorDescription: message, internalError: httpError.error)
    }
}

private struct HttpError: Decodable {
    var code: Int
    var message: String
    var details: String
}
