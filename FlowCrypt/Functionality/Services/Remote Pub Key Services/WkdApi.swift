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
    func lookup(email: String) async throws -> [KeyDetails]
}

/// Public key server - each org can run their own at a predictable url
/// FlowCrypt customers can run FlowCrypt WKD:
/// https://flowcrypt.com/docs/technical/enterprise/email-deployment-overview.html
class WkdApi: WkdApiType {

    private enum Constants {
        static let lookupEmailRequestTimeout: TimeInterval = 4
        static let apiName = "WkdApi"
    }

    private struct InternalResult {
        let hasPolicy: Bool
        let keys: Data?
        let method: WkdMethod
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

    func lookup(email: String) async throws -> [KeyDetails] {
        guard
            !Configuration.publicEmailProviderDomains.contains(email.recipientDomain ?? ""),
            let advancedUrl = urlConstructor.construct(from: email, method: .advanced),
            let directUrl = urlConstructor.construct(from: email, method: .direct)
        else {
            return []
        }
        let results: [InternalResult] = try await withThrowingTaskGroup(of: InternalResult.self) { tg in
            var results: [InternalResult] = []
            tg.addTask { try await self.urlLookup(advancedUrl, method: .advanced) }
            tg.addTask { try await self.urlLookup(directUrl, method: .direct) }
            for try await result in tg {
                results.append(result)
            }
            return results
        }
        guard let advancedResult = results.first(where: { $0.method == .advanced }) else {
            throw AppErr.unexpected("missing expected lookup method .advanced")
        }
        guard let directResult = results.first(where: { $0.method == .direct }) else {
            throw AppErr.unexpected("missing expected lookup method .direct")
        }
        if advancedResult.hasPolicy { // hasPolicy means the WKD server is running
            guard let binary = advancedResult.keys else {
                return []
            }
            return try await parseAndFilter(keysData: binary, email: email)
        }
        guard directResult.hasPolicy, let binary = directResult.keys else {
            return []
        }
        return try await parseAndFilter(keysData: binary, email: email)
    }

    private func parseAndFilter(keysData: Data, email: String) async throws -> [KeyDetails] {
        return try await core.parseKeys(armoredOrBinary: keysData).keyDetails
            .filter { !$0.users.filter { $0.contains(email) }.isEmpty }
    }

    private func urlLookup(_ urls: WkdUrls, method: WkdMethod) async throws -> InternalResult {
        do {
            let request = ApiCall.Request(
                apiName: Constants.apiName,
                url: urls.policy,
                timeout: Constants.lookupEmailRequestTimeout
            )
            _ = try await ApiCall.call(request)
        } catch {
            Logger.nested("WkdApi").logInfo("Failed to load \(urls.policy) with error \(error)")
            return InternalResult(hasPolicy: false, keys: nil, method: method)
        }

        let request = ApiCall.Request(
            apiName: Constants.apiName,
            url: urls.pubKeys,
            timeout: Constants.lookupEmailRequestTimeout,
            tolerateStatus: [404]
        )
        let pubKeyResponse = try await ApiCall.call(request)
        if !pubKeyResponse.data.toStr().isEmpty {
            Logger.nested("WKDURLsService").logInfo("Loaded WKD url \(urls.pubKeys) and will try to extract Public Keys")
        }

        if pubKeyResponse.status == 404 {
            return InternalResult(hasPolicy: true, keys: nil, method: method)
        }

        return InternalResult(hasPolicy: true, keys: pubKeyResponse.data, method: method)
    }
}
