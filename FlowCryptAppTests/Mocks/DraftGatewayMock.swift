//
//  DraftGatewayMock.swift
//  FlowCryptAppTests
//
//  Created by Evgenii Kyivskyi on 10/28/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import GoogleAPIClientForREST_Gmail

class DraftGatewayMock: DraftGateway {
    func fetchDraftId(messageId: String) async throws -> String? {
        return nil
    }

    func saveDraft(input: MessageGatewayInput, draftId: String?) async throws -> GTLRGmail_Draft {
        return GTLRGmail_Draft()
    }

    func deleteDraft(with identifier: String) async {}
}
