//
//  MessageGateway.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct MessageGatewayInput {
    let mime: Data
    let threadId: String?
}

protocol MessageGateway {
    func sendMail(input: MessageGatewayInput, progressHandler: ((Float) -> Void)?) async throws -> Identifier
}

protocol DraftGateway {
    func fetchMessage(draftIdentifier: Identifier) async throws -> Message?
    func fetchDraft(for messageId: Identifier) async throws -> MessageDraft?
    func saveDraft(input: MessageGatewayInput, draftId: Identifier?) async throws -> MessageDraft
    func deleteDraft(with identifier: Identifier) async throws
}
