//
//  PubLookup.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 31.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

protocol PubLookupType {
    func lookup(recipient: Recipient) async throws -> RecipientWithSortedPubKeys
    func fetchRemoteUpdateLocal(with recipient: Recipient) async throws -> RecipientWithSortedPubKeys
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
                LookupResult(keys: try await self.wkd.lookup(email: recipient.email), source: .wkd)
            }
            tg.addTask {
                LookupResult(keys: try await self.attesterApi.lookup(email: recipient.email), source: .attester)
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
            //  controls the distribution of the keys themselves on their own domain
            return RecipientWithSortedPubKeys(recipient, keyDetails: wkdResult.keys)
        }
        // Attester keys are less preferred because they come from less trustworthy source
        //   (the FlowCrypt server)
        return RecipientWithSortedPubKeys(recipient, keyDetails: attesterResult.keys)
    }

    func fetchRemoteUpdateLocal(with recipient: Recipient) async throws -> RecipientWithSortedPubKeys {
        let recipient = try await self.lookup(recipient: recipient)
        try localContactsProvider.updateKeys(for: recipient)
        return recipient
    }
}
