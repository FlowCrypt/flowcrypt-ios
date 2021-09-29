//
//  EmailKeyManagerApi.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 17.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Promises

protocol EmailKeyManagerApiType {

    func getPrivateKeysUrlString() -> String?
    func getPrivateKeys() -> Promise<EmailKeyManagerApiResult>
}

enum EmailKeyManagerApiError: Error {
    case noGoogleIdToken
    case noPrivateKeysUrlString
}

enum EmailKeyManagerApiResult {
    case success(keys: [CoreRes.ParseKeys])
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

class EmailKeyManagerApi: EmailKeyManagerApiType {

    private let organisationalRulesService: OrganisationalRulesServiceType
    private let core: Core

    init(
        organisationalRulesService: OrganisationalRulesServiceType = OrganisationalRulesService(),
        core: Core = .shared
    ) {
        self.organisationalRulesService = organisationalRulesService
        self.core = core
    }

    func getPrivateKeysUrlString() -> String? {
        guard let keyManagerUrlString = organisationalRulesService.getSavedOrganisationalRulesForCurrentUser().keyManagerUrlString else {
            return nil
        }
        return "\(keyManagerUrlString)v1/keys/private"
    }

    func getPrivateKeys() -> Promise<EmailKeyManagerApiResult> {
        Promise<EmailKeyManagerApiResult> { [weak self] resolve, reject in
            guard let self = self else { throw AppErr.nilSelf }
            guard let urlString = self.getPrivateKeysUrlString() else {
                reject(EmailKeyManagerApiError.noPrivateKeysUrlString)
                return
            }

            guard let idToken = GoogleUserService().idToken else {
                reject(EmailKeyManagerApiError.noGoogleIdToken)
                return
            }

            let headers = [
                URLHeader(
                    value: "Bearer \(idToken)",
                    httpHeaderField: "Authorization"
                )]
            let request = URLRequest.urlRequest(
                with: urlString,
                method: .get,
                body: nil,
                headers: headers
            )
            let response = try awaitPromise(URLSession.shared.call(request))
            let decryptedPrivateKeysResponse = try JSONDecoder().decode(DecryptedPrivateKeysResponse.self, from: response.data)

            if decryptedPrivateKeysResponse.privateKeys.isEmpty {
                resolve(.noKeys)
            }

            let privateKeys = decryptedPrivateKeysResponse.privateKeys
                .map { $0.decryptedPrivateKey.data() }
            let parsedPrivateKeys = privateKeys
                .compactMap { try? self.core.parseKeys(armoredOrBinary: $0) }
            let areKeysDecrypted = parsedPrivateKeys
                .compactMap { $0.keyDetails.map { $0.isFullyDecrypted } }
                .flatMap { $0 }

            if areKeysDecrypted.contains(false) {
                resolve(.keysAreNotDecrypted)
            }

            resolve(.success(keys: parsedPrivateKeys))
        }
    }
}
