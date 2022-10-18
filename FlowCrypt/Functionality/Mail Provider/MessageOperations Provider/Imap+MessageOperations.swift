//
//  Imap+MessageOperations.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import MailCore

extension Imap: MessageOperationsProvider {

    func markAsUnread(id: Identifier, folder: String) async throws {
        guard let identifier = id.intId else {
            throw ImapError.missingMessageInfo("intId")
        }
        try await executeVoid("markAsUnread", { sess, respond in
            sess.storeFlagsOperation(
                withFolder: folder,
                uids: MCOIndexSet(index: UInt64(identifier)),
                kind: .remove,
                flags: [.seen]
            ).start { error in respond(error) }
        })
    }

    func markAsRead(id: Identifier, folder: String) async throws {
        guard let identifier = id.intId else {
            throw ImapError.missingMessageInfo("intId")
        }
        try await executeVoid("markAsRead", { sess, respond in
            sess.storeFlagsOperation(
                withFolder: folder,
                uids: MCOIndexSet(index: UInt64(identifier)),
                kind: .add,
                flags: [.seen]
            ).start { error in respond(error) }
        })
    }

    func moveMessageToInbox(id: Identifier, folderPath: String) async throws {
        // should be implemented later
        guard id.intId != nil else {
            throw ImapError.missingMessageInfo("intId")
        }
    }

    func moveMessageToTrash(id: Identifier, trashPath: String?, from folder: String) async throws {
        guard let identifier = id.intId else {
            throw ImapError.missingMessageInfo("intId")
        }
        guard let trashPath = trashPath else {
            throw ImapError.missingMessageInfo("trashPath")
        }
        try await moveMsg(with: identifier, folder: folder, destFolder: trashPath)
    }

    private func moveMsg(with id: Int, folder: String, destFolder: String) async throws {
        try await executeVoid("moveMsg", { sess, respond in
            sess.copyMessagesOperation(
                withFolder: folder,
                uids: MCOIndexSet(index: UInt64(id)),
                destFolder: destFolder
            ).start { error, _ in respond(error) }
        })
    }

    func deleteMessage(id: Identifier, from folderPath: String?) async throws {
        guard let identifier = id.intId else {
            throw ImapError.missingMessageInfo("intId")
        }
        guard let folderPath = folderPath else {
            throw ImapError.missingMessageInfo("folderPath")
        }
        try await pushUpdatedMsgFlags(with: identifier, folder: folderPath, flags: MCOMessageFlag.deleted)
        try await expungeMsgs(folder: folderPath)
    }

    func emptyFolder(path: String) async throws {
        try await batchDeleteMessages(identifiers: [], from: path)
    }

    func batchDeleteMessages(identifiers: [String], from folderPath: String?) async throws {
        guard let folderPath = folderPath else {
            throw ImapError.missingMessageInfo("folderPath")
        }
        try await expungeMsgs(folder: folderPath)
    }

    private func pushUpdatedMsgFlags(with identifier: Int, folder: String, flags: MCOMessageFlag) async throws {
        try await executeVoid("pushUpdatedMsgFlags", { sess, respond in
            sess.storeFlagsOperation(
                withFolder: folder,
                uids: MCOIndexSet(index: UInt64(identifier)),
                kind: .set,
                flags: flags
            ).start { error in respond(error) }
        })
    }

    private func expungeMsgs(folder: String) async throws {
        try await executeVoid("expungeMsgs", { sess, respond in
            sess.expungeOperation(
                folder
            ).start { error in respond(error) }
        })
    }

    func archiveMessage(id: Identifier, folderPath: String) async throws {
        guard let identifier = id.intId else {
            throw ImapError.missingMessageInfo("intId")
        }
        try await pushUpdatedMsgFlags(with: identifier, folder: folderPath, flags: MCOMessageFlag.deleted)
    }
}
