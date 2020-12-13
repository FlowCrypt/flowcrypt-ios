//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

extension Imap {
    func fetchMsg(message: MCOIMAPMessage, folder: String) -> Promise<Data> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            self.imapSess?
                .fetchMessageOperation(withFolder: folder, uid: message.uid)
                .start(self.finalize("fetchMsg", resolve, reject, retry: { self.fetchMsg(message: message, folder: folder) }))
        }
    }

//    func moveMsg(msg: MCOIMAPMessage, folder: String, destFolder: String) -> Promise<Void> {
//        Promise<Void> { [weak self] resolve, reject in
//            guard let self = self else { return reject(AppErr.nilSelf) }
//
//            self.imapSess?
//                .copyMessagesOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(msg.uid)), destFolder: destFolder)
//                .start(self.finalizeAsVoid("moveMsg", resolve, reject, retry: { self.moveMsg(msg: msg, folder: folder, destFolder: destFolder) }))
//        }
//    }

    func pushUpdatedMsgFlags(msg: MCOIMAPMessage, folder: String) -> Promise<Void> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            self.imapSess?
                .storeFlagsOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(msg.uid)), kind: MCOIMAPStoreFlagsRequestKind.set, flags: msg.flags)
                .start(self.finalizeVoid("updateMsgFlags", resolve, reject, retry: { self.pushUpdatedMsgFlags(msg: msg, folder: folder) }))
        }
    }
}

