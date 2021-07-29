//
//  EmailKeyManagerApi.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 17.07.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Promises

protocol EmailKeyManagerApiType {

    func getPrivateKeysUrlString() -> String?
    func getPrivateKeys() -> Promise<DecryptedPrivateKeysResponse>
}

enum EmailKeyManagerApiError: Error {
    case noGoogleIdToken
    case noPrivateKeysUrlString
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

    init(organisationalRulesService: OrganisationalRulesServiceType = OrganisationalRulesService()) {
        self.organisationalRulesService = organisationalRulesService
    }

    func getPrivateKeysUrlString() -> String? {
        guard let keyManagerUrlString = organisationalRulesService.getSavedOrganisationalRulesForCurrentUser().keyManagerUrlString else {
            return nil
        }
        return "\(keyManagerUrlString)v1/keys/private"
    }

    func getPrivateKeys() -> Promise<DecryptedPrivateKeysResponse> {
        Promise<DecryptedPrivateKeysResponse> { [weak self] resolve, reject in
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
            resolve(decryptedPrivateKeysResponse)
        }
    }
}
