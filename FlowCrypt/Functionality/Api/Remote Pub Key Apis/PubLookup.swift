//
//  PubLookup.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 31.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

protocol PubLookupType {
    func lookup(recipient: Recipient) async throws -> RecipientWithSortedPubKeys
    func fetchRemoteUpdateLocal(with recipient: Recipient) async throws
}

class PubLookup: PubLookupType {
    private let wkd: WkdApiType
    private let attesterApi: AttesterApiType
    private let localContactsProvider: LocalContactsProviderType

    private enum LookupSource {
        case attester
        case wkd
    }

    private struct LookupResult {
        let keys: [KeyDetails]
        let source: LookupSource
        var error: Error?
    }

    init(
        clientConfiguration: ClientConfiguration,
        localContactsProvider: LocalContactsProviderType,
        wkd: WkdApiType = WkdApi(),
        attesterApi: AttesterApiType? = nil
    ) {
        self.wkd = wkd
        self.localContactsProvider = localContactsProvider
        self.attesterApi = attesterApi ?? AttesterApi(clientConfiguration: clientConfiguration)
    }

    func lookup(recipient: Recipient) async throws -> RecipientWithSortedPubKeys {
        let results: [LookupResult] = try await withThrowingTaskGroup(of: LookupResult.self) { tg in
            var results: [LookupResult] = []
            tg.addTask {
                try await LookupResult(keys: self.wkd.lookup(email: recipient.email), source: .wkd)
            }
            tg.addTask {
                do {
                    return try await LookupResult(
                        keys: self.attesterApi.lookup(email: recipient.email),
                        source: .attester
                    )
                } catch {
                    return LookupResult(keys: [], source: .attester, error: error)
                }
            }
            for try await result in tg {
                results.append(result)
            }
            return results
        }

        guard let wkdResult = results.first(where: { $0.source == .wkd }) else {
            throw AppErr.unexpected("expecting to find wkdResult")
        }
        guard let attesterResult = results.first(where: { $0.source == .attester }) else {
            throw AppErr.unexpected("expecting to find attesterResult")
        }

        if !wkdResult.keys.isEmpty {
            // WKD keys are preferred. The trust level is higher because the recipient
            // controls the distribution of the keys themselves on their own domain
            return try RecipientWithSortedPubKeys(recipient, keyDetails: wkdResult.keys)
        }
        // If no keys are found from WKD and attester returns error, then throw error
        if let attesterError = attesterResult.error {
            throw attesterError
        }
        // Attester keys are less preferred because they come from less trustworthy source
        // (the FlowCrypt server)
        return try RecipientWithSortedPubKeys(recipient, keyDetails: attesterResult.keys)
    }

    func fetchRemoteUpdateLocal(with recipient: Recipient) async throws {
        let remoteRecipient = try await lookup(recipient: recipient)
        try localContactsProvider.updateKeys(for: remoteRecipient)
    }
}
