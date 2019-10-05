//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

extension Imap {
    func fetchMsg(message: MCOIMAPMessage, folder: String) -> Promise<Data> {
        return Promise { resolve, reject in
            self.getImapSess()?
                .fetchMessageOperation(withFolder: folder, uid: message.uid)
                .start(self.finalize("fetchMsg", resolve, reject, retry: { self.fetchMsg(message: message, folder: folder) }))
        }
    }

    func markAsRead(message: MCOIMAPMessage, folder: String) -> Promise<Void> {
        return Promise { resolve, reject in
            self.getImapSess()?
                .storeFlagsOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(message.uid)), kind: MCOIMAPStoreFlagsRequestKind.add, flags: message.flags)
                .start(self.finalizeVoid("markAsRead", resolve, reject, retry: { self.markAsRead(message: message, folder: folder) }))
        }
    }

    func moveMsg(msg: MCOIMAPMessage, folder: String, destFolder: String) -> Promise<Void> {
        return Promise<Void> { resolve, reject in
            self.getImapSess()?
                .copyMessagesOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(msg.uid)), destFolder: destFolder)
                .start(self.finalizeAsVoid("moveMsg", resolve, reject, retry: { self.moveMsg(msg: msg, folder: folder, destFolder: destFolder) }))
        }
    }

    func pushUpdatedMsgFlags(msg: MCOIMAPMessage, folder: String) -> Promise<Void> {
        return Promise { resolve, reject in
            self.getImapSess()?
                .storeFlagsOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(msg.uid)), kind: MCOIMAPStoreFlagsRequestKind.add, flags: msg.flags)
                .start(self.finalizeVoid("updateMsgFlags", resolve, reject, retry: { self.pushUpdatedMsgFlags(msg: msg, folder: folder) }))
        }
    }
}
