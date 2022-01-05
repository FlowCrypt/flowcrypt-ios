//
//  EmailKeyManagerApi.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 17.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import FlowCryptCommon

protocol EmailKeyManagerApiType {
    func getPrivateKeys(idToken: String) async throws -> EmailKeyManagerApiResult
}

enum EmailKeyManagerApiError: Error {
    case noPrivateKeysUrlString
}

enum EmailKeyManagerApiResult {
    case success(keys: [KeyDetails])
    case noKeys
    case keysAreNotDecrypted
}

extension EmailKeyManagerApiError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noPrivateKeysUrlString: return ""
        }
    }
}

/// A customer-specific server that provides private keys
/// https://flowcrypt.com/docs/technical/enterprise/email-deployment-overview.html
actor EmailKeyManagerApi: EmailKeyManagerApiType {

    private enum Constants {
        static let apiName = "EmailKeyManagerApi"
    }

    private let clientConfiguration: ClientConfiguration
    private let core: Core

    init(
        clientConfiguration: ClientConfiguration,
        core: Core = .shared
    ) {
        self.clientConfiguration = clientConfiguration
        self.core = core
    }

    func getPrivateKeys(idToken: String) async throws -> EmailKeyManagerApiResult {
        let urlString = try getPrivateKeysUrlString()
        let headers = [
            URLHeader(
                value: "Bearer \(idToken)",
                httpHeaderField: "Authorization"
            )]
        let request = ApiCall.Request(
            apiName: Constants.apiName,
            url: urlString,
            method: .get,
            body: nil,
            headers: headers
        )
        let response = try await ApiCall.call(request)
        let decryptedPrivateKeysResponse = try JSONDecoder().decode(DecryptedPrivateKeysResponse.self, from: response.data)

        if decryptedPrivateKeysResponse.privateKeys.isEmpty {
            return .noKeys
        }

        let privateKeysArmored = decryptedPrivateKeysResponse.privateKeys
            .map(\.decryptedPrivateKey)
            .joined(separator: "\n")
            .data()
        let parsedPrivateKeys = try await core.parseKeys(armoredOrBinary: privateKeysArmored)
        // todo - check that parsedPrivateKeys don't contain public keys
        let areKeysDecrypted = parsedPrivateKeys.keyDetails
            .compactMap { $0.isFullyDecrypted }
        if areKeysDecrypted.contains(false) {
            return .keysAreNotDecrypted
        }

        return .success(keys: parsedPrivateKeys.keyDetails)
    }

    private func getPrivateKeysUrlString() throws -> String {
        guard let keyManagerUrlString = clientConfiguration.keyManagerUrlString else {
            throw EmailKeyManagerApiError.noPrivateKeysUrlString
        }
        return "\(keyManagerUrlString)v1/keys/private"
    }
}
