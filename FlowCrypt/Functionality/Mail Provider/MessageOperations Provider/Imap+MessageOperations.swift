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
            throw ImapError.missingMessageInfo("intId")
        }
        try await executeVoid("markAsUnread", { sess, respond in
            sess.storeFlagsOperation(
                withFolder: folder,
                uids: MCOIndexSet(index: UInt64(identifier)),
                kind: MCOIMAPStoreFlagsRequestKind.remove,
                flags: [MCOMessageFlag.seen]
            ).start { error in respond(error) }
        })
    }

    func markAsRead(message: Message, folder: String) async throws {
        guard let identifier = message.identifier.intId else {
            throw ImapError.missingMessageInfo("intId")
        }
        var flags: MCOMessageFlag = []
        let imapFlagValues = message.labels.map(\.imapFlagValue)
        // keep previous flags
        for value in imapFlagValues {
            flags.insert(MCOMessageFlag(rawValue: value))
        }
        // add seen flag
        flags.insert(MCOMessageFlag.seen)
        try await executeVoid("markAsRead", { sess, respond in
            sess.storeFlagsOperation(
                withFolder: folder,
                uids: MCOIndexSet(index: UInt64(identifier)),
                kind: MCOIMAPStoreFlagsRequestKind.add,
                flags: flags
            ).start { error in respond(error) }
        })
    }

    func moveMessageToInbox(message: Message, folderPath: String) async throws {
        // should be implemented later
        guard message.identifier.intId != nil else {
            throw ImapError.missingMessageInfo("intId")
        }
    }

    func moveMessageToTrash(message: Message, trashPath: String?, from folder: String) async throws {
        guard let identifier = message.identifier.intId else {
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

    func delete(message: Message, from folderPath: String?) async throws {
        guard let identifier = message.identifier.intId else {
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
                kind: MCOIMAPStoreFlagsRequestKind.set,
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

    func archiveMessage(message: Message, folderPath: String) async throws {
        guard let identifier = message.identifier.intId else {
            throw ImapError.missingMessageInfo("intId")
        }
        try await pushUpdatedMsgFlags(with: identifier, folder: folderPath, flags: MCOMessageFlag.deleted)
    }
}
