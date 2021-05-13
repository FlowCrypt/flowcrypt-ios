//
//  Imap+MessageOperations.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.12.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

extension Imap: MessageOperationsProvider {
    // MARK: - read
    func markAsRead(message: Message, folder: String) -> Promise<Void> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            guard let identifier = message.identifier.intId else {
                return reject(ImapError.missedMessageInfo("intId"))
            }

            var flags: MCOMessageFlag = []
            let imapFlagValues = message.labels.map(\.type.imapFlagValue)
            // keep previous flags
            for value in imapFlagValues {
                flags.insert(MCOMessageFlag(rawValue: value))
            }
            // add seen flag
            flags.insert(MCOMessageFlag.seen)

            self.imapSess?
                .storeFlagsOperation(
                    withFolder: folder,
                    uids: MCOIndexSet(index: UInt64(identifier)),
                    kind: MCOIMAPStoreFlagsRequestKind.add,
                    flags: flags
                )
                .start(self.finalizeVoid("markAsRead", resolve, reject, retry: { self.markAsRead(message: message, folder: folder) }))
        }
    }

    // MARK: - trash
    func moveMessageToTrash(message: Message, trashPath: String?, from folder: String) -> Promise<Void> {
        Promise<Void> { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            guard let identifier = message.identifier.intId else {
                return reject(ImapError.missedMessageInfo("intId"))
            }

            guard let trashPath = trashPath else {
                return reject(ImapError.missedMessageInfo("trashPath"))
            }

            try awaitPromise(self.moveMsg(with: identifier, folder: folder, destFolder: trashPath))
            resolve(())
        }
    }

    private func moveMsg(with identifier: Int, folder: String, destFolder: String) -> Promise<Void> {
        Promise<Void> { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            self.imapSess?
                .copyMessagesOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(identifier)), destFolder: destFolder)
                .start(self.finalizeAsVoid("moveMsg", resolve, reject, retry: { self.moveMsg(with: identifier, folder: folder, destFolder: destFolder) }))
        }
    }

    // MARK: - delete
    func delete(message: Message, form folderPath: String?) -> Promise<Void> {
        Promise<Void> { [weak self] _, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            guard let identifier = message.identifier.intId else {
                return reject(ImapError.missedMessageInfo("intId"))
            }

            guard let folderPath = folderPath else {
                return reject(ImapError.missedMessageInfo("folderPath"))
            }

            try awaitPromise(self.pushUpdatedMsgFlags(with: identifier, folder: folderPath, flags: MCOMessageFlag.deleted))
            try awaitPromise(self.expungeMsgs(folder: folderPath))
        }
    }

    private func pushUpdatedMsgFlags(with identifier: Int, folder: String, flags: MCOMessageFlag) -> Promise<Void> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            let retry = self.pushUpdatedMsgFlags(with: identifier, folder: folder, flags: flags)
            self.imapSess?
                .storeFlagsOperation(
                    withFolder: folder,
                    uids: MCOIndexSet(index: UInt64(identifier)),
                    kind: MCOIMAPStoreFlagsRequestKind.set,
                    flags: flags
                )
                .start(self.finalizeVoid("updateMsgFlags", resolve, reject, retry: { retry }))
        }
    }

    private func expungeMsgs(folder: String) -> Promise<Void> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { throw AppErr.nilSelf }

            self.imapSess?
                .expungeOperation(folder)
                .start(self.finalizeVoid("expungeMsgs", resolve, reject, retry: { self.expungeMsgs(folder: folder) }))
        }
    }

    // MARK: - archive
    func archiveMessage(message: Message, folderPath: String) -> Promise<Void> {
        Promise<Void> { [weak self] _, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            guard let identifier = message.identifier.intId else {
                return reject(ImapError.missedMessageInfo("intId"))
            }

            try awaitPromise(self.pushUpdatedMsgFlags(with: identifier, folder: folderPath, flags: MCOMessageFlag.deleted))
        }
    }
}
