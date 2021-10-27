//
//  DraftGatewayMock.swift
//  FlowCryptAppTests
//
//  Created by Evgenii Kyivskyi on 10/28/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import Foundation
import GoogleAPIClientForREST_Gmail

class DraftGatewayMock: DraftGateway {
    func saveDraft(input: MessageGatewayInput, draft: GTLRGmail_Draft?) async throws -> GTLRGmail_Draft {
        return GTLRGmail_Draft()
    }

    func getDraft(with identifier: String) async throws -> GTLRGmail_Draft {
        return GTLRGmail_Draft()
    }

    func deleteDraft(with identifier: String) async {}
}
