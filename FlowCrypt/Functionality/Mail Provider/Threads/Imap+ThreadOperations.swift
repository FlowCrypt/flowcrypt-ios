//
//  Imap+ThreadOperations.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 30.12.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

// TODO: - Rework in scope of https://github.com/FlowCrypt/flowcrypt-ios/issues/1260
extension Imap: MessagesThreadOperationsApiClient {
    private var error: Error { AppErr.general("Doesn't support yet") }

    func delete(id: String?) async throws {
        throw error
    }

    func moveThreadToTrash(id: String?, labels: Set<MessageLabel>) async throws {
        throw error
    }

    func moveThreadToInbox(id: String?) async throws {
        throw error
    }

    func markThreadAsUnread(id: String?, folder: String) async throws {
        throw error
    }

    func markThreadAsRead(id: String?, folder: String) async throws {
        throw error
    }

    func mark(messagesIds: [Identifier], asRead: Bool, in folder: String) async throws {
        throw error
    }

    func archive(messagesIds: [Identifier], in folder: String) async throws {
        throw error
    }
}
