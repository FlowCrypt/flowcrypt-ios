//
//  PubLookup.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 31.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

protocol PubLookupType {
    func lookup(with email: String) async throws -> RecipientWithSortedPubKeys
}

class PubLookup: PubLookupType {
    private let wkd: WkdApiType
    private let attesterApi: AttesterApiType

    private enum PubLookupSource {
        case attester
        case wkd
    }

    private struct Result {
        let keys: [KeyDetails]
        let source: PubLookupSource
    }

    init(
        wkd: WkdApiType = WkdApi(),
        attesterApi: AttesterApiType = AttesterApi()
    ) {
        self.wkd = wkd
        self.attesterApi = attesterApi
    }

    func lookup(with email: String) async throws -> RecipientWithSortedPubKeys {
        let results: [Result] = try await withThrowingTaskGroup(of: Result.self) { tg in
            var results: [Result] = []
            tg.addTask {
                Result(keys: try await self.wkd.lookupEmail(email), source: .wkd)
            }
            tg.addTask {
                Result(keys: try await self.attesterApi.lookupEmail(email), source: .attester)
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
            return RecipientWithSortedPubKeys(email: email, keyDetails: wkdResult.keys)
        }
        // Attester keys are less preferred because they come from less trustworthy source
        //   (the FlowCrypt server)
        return RecipientWithSortedPubKeys(email: email, keyDetails: attesterResult.keys)
    }
}
