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
}
