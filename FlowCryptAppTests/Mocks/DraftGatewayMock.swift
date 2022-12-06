//
//  DraftGatewayMock.swift
//  FlowCryptAppTests
//
//  Created by Evgenii Kyivskyi on 10/28/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt

class DraftsApiClientMock: DraftsApiClient {
    func fetchDraft(id: Identifier) async throws -> MessageIdentifier? {
        return nil
    }

    func fetchDraftIdentifier(for messageId: Identifier) async throws -> MessageIdentifier? {
        return nil
    }

    func saveDraft(input: MessageGatewayInput, draftId: Identifier?) async throws -> MessageIdentifier {
        return MessageIdentifier(draftId: draftId ?? .random, threadId: nil, messageId: nil)
    }

    func deleteDraft(with identifier: Identifier) async {}
}
