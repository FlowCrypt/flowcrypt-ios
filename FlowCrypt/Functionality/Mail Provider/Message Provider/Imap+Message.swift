//
//  Imap+Message.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

extension Imap: MessageProvider {
    func fetchMessage(
        id: Identifier,
        folder: String
    ) async throws -> Message {
        throw AppErr.unexpected("Not implemented")
//        guard let identifier = id.intId else {
//            throw AppErr.unexpected("Missing message identifier")
//        }
//        return try await execute("fetchMsg", { sess, respond in
//            sess.fetchMessageOperation(
//                withFolder: folder,
//                uid: UInt32(identifier)
//            ).start { error, data in respond(error, data) }
//        })
    }

    func fetchRawMessage(id: Identifier) async throws -> String {
        throw AppErr.unexpected("Not implemented")
    }

    func fetchAttachment(
        id: Identifier,
        messageId: Identifier,
        estimatedSize: Float?,
        progressHandler: ((Float) -> Void)?
    ) async throws -> Data {
        throw AppErr.unexpected("Should be implemented")
//        guard let identifier = id.stringId else {
//            throw AppErr.unexpected("Missing message attachment identifier")
//        }
//        guard let messageIdentifier = messageId.stringId else {
//            throw AppErr.unexpected("Missing message identifier")
//        }
    }
}
