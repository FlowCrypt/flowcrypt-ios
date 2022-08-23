//
//  Imap+Message.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

extension Imap: MessageProvider {
    func fetchMsg(
        id: Identifier,
        folder: String,
        progressHandler: ((MessageFetchState) -> Void)?
    ) async throws -> Message {
        guard let identifier = id.intId else {
            throw AppErr.unexpected("Missing message identifier")
        }
        // TODO: Should return Message instead of Data
        throw AppErr.unexpected("Should be implemented")
//        return try await execute("fetchMsg", { sess, respond in
//            sess.fetchMessageOperation(
//                withFolder: folder,
//                uid: UInt32(identifier)
//            ).start { error, data in respond(error, data) }
//        })
    }

    func fetchAttachment(
        id: Identifier,
        messageId: Identifier,
        progressHandler: ((MessageFetchState) -> Void)?
    ) async throws -> Data {
        guard let identifier = id.stringId else {
            throw AppErr.unexpected("Missing message attachment identifier")
        }
        guard let messageIdentifier = messageId.stringId else {
            throw AppErr.unexpected("Missing message identifier")
        }
        throw AppErr.unexpected("Should be implemented")
    }
}
