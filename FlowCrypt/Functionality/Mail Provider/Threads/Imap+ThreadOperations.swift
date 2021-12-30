//
//  Imap+ThreadOperations.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 30.12.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

// TODO: - Rework in scope of https://github.com/FlowCrypt/flowcrypt-ios/issues/1260
extension Imap: MessagesThreadOperationsProvider {
    private var error: Error { AppErr.general("Doesn't support yet") }

    func mark(thread: MessageThread, asRead: Bool, in folder: String) async throws {
        throw error
    }

    func delete(thread: MessageThread) async throws {
        throw error
    }

    func moveThreadToTrash(thread: MessageThread) async throws {
        throw error
    }

    func markThreadAsUnread(thread: MessageThread, folder: String) async throws {
        throw error
    }

    func markThreadAsRead(thread: MessageThread, folder: String) async throws {
        throw error
    }

    func archive(thread: MessageThread, in folder: String) async throws {
        throw error
    }
}
