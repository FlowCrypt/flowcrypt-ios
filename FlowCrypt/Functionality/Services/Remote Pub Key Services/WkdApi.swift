//
//  WkdApi.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 23.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import CryptoKit
import FlowCryptCommon

protocol WkdApiType {
    func lookupEmail(_ email: String) async throws -> [KeyDetails]
}

/// Public key server - each org can run their own at a predictable url
/// FlowCrypt customers can run FlowCrypt WKD:
/// https://flowcrypt.com/docs/technical/enterprise/email-deployment-overview.html
class WkdApi: WkdApiType {

    private enum Constants {
        static let lookupEmailRequestTimeout: TimeInterval = 4
    }

    private let urlConstructor: WkdUrlConstructorType
    private let core: Core

    init(
        urlConstructor: WkdUrlConstructorType = WkdUrlConstructor(),
        core: Core = Core.shared
    ) {
        self.urlConstructor = urlConstructor
        self.core = core
    }

    func lookupEmail(_ email: String) async throws -> [KeyDetails] {
        return try await rawLookupEmail(email)?.keyDetails
            .filter { !$0.users.filter { $0.contains(email) }.isEmpty } ?? []
    }

    func rawLookupEmail(_ email: String) async throws -> CoreRes.ParseKeys? {
        guard
            !Configuration.publicEmailProviderDomains.contains(email.recipientDomain ?? ""),
            let advancedUrl = urlConstructor.construct(from: email, method: .advanced),
            let directUrl = urlConstructor.construct(from: email, method: .direct)
        else {
            return nil
        }

        var response: (hasPolicy: Bool, key: Data?)?
        response = try await urlLookup(advancedUrl)
        if response?.hasPolicy == true && response?.key == nil {
            return nil
        }

        if response?.key == nil {
            response = try await urlLookup(directUrl)
            if response?.key == nil {
                return nil
            }
        }

        guard let binaryKeysData = response?.key else {
            return nil
        }

        return try? core.parseKeys(armoredOrBinary: binaryKeysData)
    }
}

extension WkdApi {

    private func urlLookup(_ urls: WkdUrls) async throws -> (hasPolicy: Bool, key: Data?) {
        do {
            var request = URLRequest.urlRequest(with: urls.policy)
            request.timeoutInterval = Constants.lookupEmailRequestTimeout
            _ = try await ApiCall.asyncCall(request)
        } catch {
            Logger.nested("WkdApi").logInfo("Failed to load \(urls.policy) with error \(error)")
            return (hasPolicy: false, key: nil)
        }

        var request = URLRequest.urlRequest(with: urls.pubKeys)
        request.timeoutInterval = Constants.lookupEmailRequestTimeout
        let pubKeyResponse = try await ApiCall.asyncCall(
            request,
            tolerateStatus: [404]
        )
        if !pubKeyResponse.data.toStr().isEmpty {
            Logger.nested("WKDURLsService").logInfo("Loaded WKD url \(urls.pubKeys) and will try to extract Public Keys")
        }

        if pubKeyResponse.status == 404 {
            return (hasPolicy: true, key: nil)
        }

        return (true, pubKeyResponse.data)
    }
}
