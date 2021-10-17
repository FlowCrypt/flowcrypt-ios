//
//  WkdApi.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 23.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import CryptoKit
import FlowCryptCommon
import Promises

protocol WkdApiType {
    func lookupEmail(_ email: String) -> Promise<[KeyDetails]>
}

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

    func lookupEmail(_ email: String) -> Promise<[KeyDetails]> {
        Promise<[KeyDetails]> { [weak self] resolve, _ in
            guard let self = self else { return }
            let response = try awaitPromise(self.rawLookupEmail(email))
            guard let safeResponse = response else {
                resolve([])
                return
            }
            let pubKeys = safeResponse.keyDetails
                    .filter { !$0.users.filter { $0.contains(email) }.isEmpty }
            resolve(pubKeys)
        }
        .timeout(Constants.lookupEmailRequestTimeout)
        .recoverFromTimeOut(result: [])
    }

    func rawLookupEmail(_ email: String) -> Promise<CoreRes.ParseKeys?> {
        guard
            !Configuration.publicEmailProviderDomains.contains(email.recipientDomain ?? ""),
            let advancedUrl = urlConstructor.construct(from: email, method: .advanced),
            let directUrl = urlConstructor.construct(from: email, method: .direct)
        else {
            return Promise { resolve, _ in resolve(nil) }
        }

        return Promise<CoreRes.ParseKeys?> { [weak self] resolve, _ in
            guard let self = self else { return }
            var response: (hasPolicy: Bool, key: Data?)?
            response = try awaitPromise(self.urlLookup(advancedUrl))
            if response?.hasPolicy == true && response?.key == nil {
                resolve(nil)
                return
            }
            if response?.key == nil {
                response = try awaitPromise(self.urlLookup(directUrl))
                if response?.key == nil {
                    resolve(nil)
                    return
                }
            }
            guard let binaryKeysData = response?.key else {
                resolve(nil)
                return
            }
            resolve(try? self.core.parseKeys(armoredOrBinary: binaryKeysData))
        }
    }
}

extension WkdApi {

    private func urlLookup(_ urls: WkdUrls) -> Promise<(hasPolicy: Bool, key: Data?)> {
        return Promise<(hasPolicy: Bool, key: Data?)> { resolve, _ in
            do {
                _ = try awaitPromise(URLSession.shared.call(URLRequest.urlRequest(with: urls.policy)))
            } catch {
                Logger.nested("WkdApi").logInfo("Failed to load \(urls.policy) with error \(error)")
                resolve((hasPolicy: false, key: nil))
                return
            }
            let pubKeyResponse = try awaitPromise(URLSession.shared.call(
                URLRequest.urlRequest(with: urls.pubKeys),
                tolerateStatus: [404])
            )
            if !pubKeyResponse.data.toStr().isEmpty {
                Logger.nested("WKDURLsService").logInfo("Loaded WKD url \(urls.pubKeys) and will try to extract Public Keys")
            }
            if pubKeyResponse.status == 404 {
                resolve((hasPolicy: true, key: nil))
                return
            }
            resolve((true, pubKeyResponse.data))
        }
    }
}
