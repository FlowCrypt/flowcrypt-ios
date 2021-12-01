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
        message: Message,
        folder: String,
        progressHandler: ((MessageFetchState) -> Void)?
    ) async throws -> Data {
        guard let identifier = message.identifier.intId else {
            throw AppErr.unexpected("Missing message identifier")
        }
        return try await execute("fetchMsg", { sess, respond in
            sess.fetchMessageOperation(
                withFolder: folder,
                uid: UInt32(identifier)
            ).start { error, data in respond(error, data) }
        })
    }
}
