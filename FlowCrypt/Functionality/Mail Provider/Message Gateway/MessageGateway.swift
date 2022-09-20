//
//  MessageGateway.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import GoogleAPIClientForREST_Gmail

struct MessageGatewayInput {
    let mime: Data
    let threadId: String?
}

protocol MessageGateway {
    func sendMail(input: MessageGatewayInput, progressHandler: ((Float) -> Void)?) async throws -> Identifier
}

protocol DraftGateway {
    func fetchDraftId(messageId: String) async throws -> String?
    func saveDraft(input: MessageGatewayInput, draftId: String?) async throws -> GTLRGmail_Draft
    func deleteDraft(with identifier: String) async throws
}
