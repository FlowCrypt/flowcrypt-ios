//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import Promises 

final class Imap { 
    static let instance = Imap()

    let inboxFolder = "INBOX"
    var imapSess: MCOIMAPSession?
    var smtpSess: MCOSMTPSession?

    typealias ReqKind = MCOIMAPMessagesRequestKind
    typealias Err = MCOErrorCode

    var lastErr: [String: FCError] = [:]

    let userService: UserService
    let dataManager: DataManager

    var email: String {
        return dataManager.currentUser()?.email ?? ""
    }
    var name: String {
        return dataManager.currentUser()?.name ?? ""
    }
    var token: String {
        return dataManager.currentToken() ?? ""
    }

    private init(userService: UserService = UserService.shared, dataManager: DataManager = .shared) {
        self.userService = userService
        self.dataManager = dataManager

        setup()
    }

    private func setup() {
        guard let token = dataManager.currentToken() else { return }
        getImapSess(newAccessToken: token)
    }
}

@available(*, deprecated, message: "Need to be refactored")
extension Imap {
    func fetchMsg(message: MCOIMAPMessage, folder: String) -> Promise<Data> { return Promise { resolve, reject in
        self.getImapSess()?
            .fetchMessageOperation(withFolder: folder, uid: message.uid)
            .start(self.finalize("fetchMsg", resolve, reject, retry: { self.fetchMsg(message: message, folder: folder) }))
        }}

    @discardableResult
    func markAsRead(message: MCOIMAPMessage, folder: String) -> Promise<VOID> { return Promise<VOID> { resolve, reject in
        self.getImapSess()?
            .storeFlagsOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(message.uid)), kind: MCOIMAPStoreFlagsRequestKind.add, flags: message.flags)
            .start(self.finalizeVoid("markAsRead", resolve, reject, retry: { self.markAsRead(message: message, folder: folder) }))
        }}

    func moveMsg(msg: MCOIMAPMessage, folder: String, destFolder: String) -> Promise<VOID> { return Promise<VOID> { resolve, reject in
        self.getImapSess()?
            .copyMessagesOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(msg.uid)), destFolder: destFolder)
            .start(self.finalizeAsVoid("moveMsg", resolve, reject, retry: { self.moveMsg(msg: msg, folder: folder, destFolder: destFolder) }))
        }}

    func pushUpdatedMsgFlags(msg: MCOIMAPMessage, folder: String) -> Promise<VOID> { return Promise<VOID> { resolve, reject in
        self.getImapSess()?
            .storeFlagsOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(msg.uid)), kind: MCOIMAPStoreFlagsRequestKind.add, flags: msg.flags)
            .start(self.finalizeVoid("updateMsgFlags", resolve, reject, retry: { self.pushUpdatedMsgFlags(msg: msg, folder: folder) }))
        }}

    func sendMail(mime: Data) -> Promise<VOID> { return Promise<VOID> { resolve, reject in
        self.getSmtpSess()?
            .sendOperation(with: mime)
            .start(self.finalizeVoid("send", resolve, reject, retry: { self.sendMail(mime: mime) }))
        }}
}
