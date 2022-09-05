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
    func getPrivateKeys(idToken: String) async throws -> [KeyDetails]
}

enum EmailKeyManagerApiError: Error {
    case keysAreNotDecrypted
    case keysAreInvalid
    case keysAreUnexpectedlyEncrypted
    case noPrivateKeysUrlString
    case wrongOrgRule
}

extension EmailKeyManagerApiError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noPrivateKeysUrlString: return ""
        case .keysAreNotDecrypted: return "organisational_rules_ekm_keys_are_not_decrypted_error".localized
        case .keysAreInvalid: return "organisational_rules_ekm_keys_are_invalid_error".localized
        case .keysAreUnexpectedlyEncrypted: return "organisational_rules_ekm_keys_are_unexpectedly_encrypted_error".localized
        case .wrongOrgRule:
            return "organisational_rules_wrong_config".localized
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

    func getPrivateKeys(idToken: String) async throws -> [KeyDetails] {
        let urlString = try getPrivateKeysUrlString()
        let headers = [
            URLHeader(
                value: "Bearer \(idToken)",
                httpHeaderField: "Authorization"
            )
        ]
        let request = ApiCall.Request(
            apiName: Constants.apiName,
            url: urlString,
            method: .get,
            body: nil,
            headers: headers
        )
        let response = try await ApiCall.call(request)

        let decryptedPrivateKeysResponse = try JSONDecoder().decode(
            DecryptedPrivateKeysResponse.self,
            from: response.data
        )

        let validKeys = try await validate(decryptedPrivateKeysResponse: decryptedPrivateKeysResponse)
        return validKeys
    }

    func validate(decryptedPrivateKeysResponse: DecryptedPrivateKeysResponse) async throws -> [KeyDetails] {
        var keys: [KeyDetails] = []
        for privateKey in decryptedPrivateKeysResponse.privateKeys {
            let parsedPrivateKey = try await core.parseKeys(armoredOrBinary: privateKey.decryptedPrivateKey.data())
            // todo - check that parsedPrivateKeys don't contain public keys
            let isKeyDecrypted = parsedPrivateKey.keyDetails.compactMap(\.isFullyDecrypted)
            if isKeyDecrypted.contains(false) {
                throw EmailKeyManagerApiError.keysAreNotDecrypted
            }
            if parsedPrivateKey.keyDetails.count != 1 {
                throw EmailKeyManagerApiError.keysAreInvalid
            }
            keys.append(contentsOf: parsedPrivateKey.keyDetails)
        }
        return keys
    }

    private func getPrivateKeysUrlString() throws -> String {
        guard let keyManagerUrlString = clientConfiguration.keyManagerUrlString else {
            throw EmailKeyManagerApiError.noPrivateKeysUrlString
        }
        return "\(keyManagerUrlString)v1/keys/private"
    }
}
