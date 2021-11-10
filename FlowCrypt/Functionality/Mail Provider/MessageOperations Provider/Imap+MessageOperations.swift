//
//  Imap+MessageOperations.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import MailCore

extension Imap: MessageOperationsProvider {

    func markAsUnread(message: Message, folder: String) async throws {
        guard let identifier = message.identifier.intId else {
            throw ImapError.missedMessageInfo("intId")
        }
        try await execute("markAsUnread", { sess, respond in
            sess.storeFlagsOperation(
                withFolder: folder,
                uids: MCOIndexSet(index: UInt64(identifier)),
                kind: MCOIMAPStoreFlagsRequestKind.remove,
                flags: [MCOMessageFlag.seen]
            ).start { error, value in respond(error, value) }
        })
    }

    func markAsRead(message: Message, folder: String) async throws {
        guard let identifier = message.identifier.intId else {
            throw ImapError.missedMessageInfo("intId")
        }
        var flags: MCOMessageFlag = []
        let imapFlagValues = message.labels.map(\.type.imapFlagValue)
        // keep previous flags
        for value in imapFlagValues {
            flags.insert(MCOMessageFlag(rawValue: value))
        }
        // add seen flag
        flags.insert(MCOMessageFlag.seen)
        try await execute("markAsRead", { sess, respond in
            sess.storeFlagsOperation(
                withFolder: folder,
                uids: MCOIndexSet(index: UInt64(identifier)),
                kind: MCOIMAPStoreFlagsRequestKind.add,
                flags: flags
            ).start { error, value in respond(error, value) }
        })
    }

    func moveMessageToTrash(message: Message, trashPath: String?, from folder: String) async throws {
        guard let identifier = message.identifier.intId else {
            throw ImapError.missedMessageInfo("intId")
        }
        guard let trashPath = trashPath else {
            throw ImapError.missedMessageInfo("trashPath")
        }
        try await moveMsg(with: identifier, folder: folder, destFolder: trashPath)
    }

    private func moveMsg(with id: Int, folder: String, destFolder: String) async throws {
        try await execute("moveMsg", { sess, respond in
            sess.copyMessagesOperation(
                withFolder: folder,
                uids: MCOIndexSet(index: UInt64(id)),
                destFolder: destFolder
            ).start { error, value in respond(error, value) }
        })
    }

    func delete(message: Message, form folderPath: String?) async throws {
        guard let identifier = message.identifier.intId else {
            throw ImapError.missedMessageInfo("intId")
        }
        guard let folderPath = folderPath else {
            throw ImapError.missedMessageInfo("folderPath")
        }
        try await pushUpdatedMsgFlags(with: identifier, folder: folderPath, flags: MCOMessageFlag.deleted)
        try await expungeMsgs(folder: folderPath)
    }

    private func pushUpdatedMsgFlags(with identifier: Int, folder: String, flags: MCOMessageFlag) async throws {
        try await execute("pushUpdatedMsgFlags", { sess, respond in
            sess.storeFlagsOperation(
                withFolder: folder,
                uids: MCOIndexSet(index: UInt64(identifier)),
                kind: MCOIMAPStoreFlagsRequestKind.set,
                flags: flags
            ).start { error, value in respond(error, value) }
        })
    }

    private func expungeMsgs(folder: String) async throws {
        try await execute("expungeMsgs", { sess, respond in
            sess.expungeOperation(
                folder
            ).start { error, value in respond(error, value) }
        })
    }

    func archiveMessage(message: Message, folderPath: String) async throws {
        guard let identifier = message.identifier.intId else {
            throw ImapError.missedMessageInfo("intId")
        }
        try await pushUpdatedMsgFlags(with: identifier, folder: folderPath, flags: MCOMessageFlag.deleted)
    }
}
