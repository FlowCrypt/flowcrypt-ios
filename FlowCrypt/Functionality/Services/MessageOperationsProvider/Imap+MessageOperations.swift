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
    func markAsRead(message: Message, folder: String) -> Promise<Void> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            guard let id = message.identifier.intId else {
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
                    uids: MCOIndexSet(index: UInt64(id)),
                    kind: MCOIMAPStoreFlagsRequestKind.add,
                    flags: flags
                )
                .start(self.finalizeVoid("markAsRead", resolve, reject, retry: { self.markAsRead(message: message, folder: folder) }))
        }
    }

    func moveMessageToTrash(message: Message, trashPath: String?, from folder: String) -> Promise<Void> {
        return Promise<Void> { [weak self] (resolve, reject) in
            guard let self = self else { return reject(AppErr.nilSelf) }

            guard let id = message.identifier.intId else {
                return reject(ImapError.missedMessageInfo("intId"))
            }

            guard let trashPath = trashPath else {
                return reject(ImapError.missedMessageInfo("trashPath"))
            }

            try await(self.moveMsg(with: id, folder: folder, destFolder: trashPath))
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
}
