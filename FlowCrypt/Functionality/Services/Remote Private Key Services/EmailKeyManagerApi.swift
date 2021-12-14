//
//  EmailKeyManagerApi.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 17.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

protocol EmailKeyManagerApiType {
    func getPrivateKeys(currentUserEmail: String) async throws -> EmailKeyManagerApiResult
}

enum EmailKeyManagerApiError: Error {
    case noGoogleIdToken
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
        case .noGoogleIdToken: return "emai_keymanager_api_no_google_id_token_error_description".localized
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

    func getPrivateKeys(currentUserEmail: String) async throws -> EmailKeyManagerApiResult {
        guard let urlString = getPrivateKeysUrlString() else {
            throw EmailKeyManagerApiError.noPrivateKeysUrlString
        }

        let googleService = GoogleUserService(
            currentUserEmail: currentUserEmail,
            appDelegateGoogleSessionContainer: nil // only needed when signing in/out
        )

        guard let idToken = try? await googleService.getIdToken()
        else { throw EmailKeyManagerApiError.noGoogleIdToken }

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
            .map { $0.decryptedPrivateKey }
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

    private func getPrivateKeysUrlString() -> String? {
        guard let keyManagerUrlString = clientConfiguration.keyManagerUrlString else {
            return nil
        }
        return "\(keyManagerUrlString)v1/keys/private"
    }
}
