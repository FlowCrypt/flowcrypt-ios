//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import Promises

class Imap {

    static let instance = Imap()
    var totalNumberOfInboxMsgs: Int32 = 0
    var messages = [MCOIMAPMessage]()
    let inboxFolder = "INBOX"
    var imapSess: MCOIMAPSession?
    var smtpSess: MCOSMTPSession?

    struct EmptyError: Error {}
    private typealias ReqKind = MCOIMAPMessagesRequestKind
    private var lastErr: MCOErrorCode?;
    
    func getImapSess(newAccessToken: String? = nil) -> MCOIMAPSession {
        if imapSess == nil || newAccessToken != nil {
            print("IMAP: creating a new session")
            imapSess = MCOIMAPSession()
            imapSess!.hostname = "imap.gmail.com"
            imapSess!.port = 993
            imapSess!.connectionType = MCOConnectionType.TLS
            imapSess!.authType = MCOAuthType.xoAuth2
            imapSess!.username = GoogleApi.instance.getEmail()
            imapSess!.password = nil
            imapSess!.oAuth2Token = newAccessToken ?? GoogleApi.instance.getAccessToken()
            imapSess!.authType = MCOAuthType.xoAuth2
            imapSess!.connectionType = MCOConnectionType.TLS
        }
        return imapSess!
    }

    func getSmtpSess(newAccessToken: String? = nil) -> MCOSMTPSession {
        if smtpSess == nil || newAccessToken != nil {
            print("SMTP: creating a new session")
            smtpSess = MCOSMTPSession()
            smtpSess!.hostname = "smtp.gmail.com"
            smtpSess!.port = 465
            smtpSess!.connectionType = MCOConnectionType.TLS
            smtpSess!.authType = MCOAuthType.xoAuth2
            smtpSess!.username = GoogleApi.instance.getEmail()
            smtpSess!.password = nil
            smtpSess!.oAuth2Token = newAccessToken ?? GoogleApi.instance.getAccessToken()
        }
        return smtpSess!
    }

    private func fetchFolderInfo(_ folder: String) -> Promise<MCOIMAPFolderInfo> { return Promise<MCOIMAPFolderInfo> { resolve, reject in
        self.getImapSess()
            .folderInfoOperation(folder)
            .start(self.finalize("fetchFolderInfo", resolve, reject, retry: { self.fetchFolderInfo(folder) }))
    }}

    private func fetchMsgsByNumber(_ folder: String, kind: MCOIMAPMessagesRequestKind, range: MCORange) -> Promise<[MCOIMAPMessage]> { return Promise<[MCOIMAPMessage]> { resolve, reject in
        let start = DispatchTime.now()
        self.getImapSess()
            .fetchMessagesByNumberOperation(withFolder: folder, requestKind: kind, numbers: MCOIndexSet(range: range))
            .start { error, msgs, vanishedMsgs in
                self.log("fetchMsgsByNumber", error: error, res: nil, start: start)
                guard self.retryAuthErrorNotNeeded(error, resolve, reject, retry: { self.fetchMsgsByNumber(folder, kind: kind, range: range) }) else { return }
                if error != nil {
                    reject(error!)
                } else {
                    let messages = msgs as? [MCOIMAPMessage]
                    if messages == nil {
                        reject(Errors.valueError("fetchMessagesByNumber messages == nil"))
                    } else {
                        self.messages.append(contentsOf: messages!)
                        self.messages.sort { $0.header.date > $1.header.date }
                        resolve(self.messages)
                    }
                }
            }
    }}

    func fetchLastMsgs(count: Int, folder: String) -> Promise<[MCOIMAPMessage]> { return Promise<[MCOIMAPMessage]>.valueReturning {
        let kind = ReqKind.headers.rawValue | ReqKind.structure.rawValue | ReqKind.internalDate.rawValue | ReqKind.headerSubject.rawValue | ReqKind.flags.rawValue
        let folderInfo = try await(self.fetchFolderInfo(folder))
        let didTotalNumberOfMsgsChange = Int32(self.totalNumberOfInboxMsgs) != folderInfo.messageCount
        self.totalNumberOfInboxMsgs = folderInfo.messageCount
        var numberOfMsgsToLoad = min(self.totalNumberOfInboxMsgs, Int32(count))
        if numberOfMsgsToLoad == 0 {
            return []
        }
        let fetchRange: MCORange
        if (!didTotalNumberOfMsgsChange && self.messages.count > 0) {
            // if total number of messages did not change since last fetch, assume nothing was deleted since our last fetch and fetch what we don't have
            numberOfMsgsToLoad -= Int32(self.messages.count)
            fetchRange = MCORangeMake(UInt64(self.totalNumberOfInboxMsgs - Int32(self.messages.count) - (numberOfMsgsToLoad - 1)), UInt64(numberOfMsgsToLoad - 1))
        } else { // else fetch the last N messages
            fetchRange = MCORangeMake(UInt64(self.totalNumberOfInboxMsgs - (numberOfMsgsToLoad - 1)), (UInt64(numberOfMsgsToLoad - 1)))
        }
        return try await(self.fetchMsgsByNumber(folder, kind: ReqKind(rawValue: kind), range: fetchRange))
    }}

    func fetchFolders() -> Promise<FetchFoldersRes> { return Promise<FetchFoldersRes> { resolve, reject in
        let start = DispatchTime.now()
        self.getImapSess().fetchAllFoldersOperation().start { (error, res) in
            self.log("fetchMsgs", error: error, res: res, start: start)
            guard self.retryAuthErrorNotNeeded(error, resolve, reject, retry: { self.fetchFolders() }) else { return }
            guard let arr = res as NSArray? else {
                reject(Errors.valueError("Response from fetchFolders not a NSArray, instead got \(String(describing: res))"))
                return;
            }
            var menu = [String]()
            var folders = [MCOIMAPFolder]()
            for f in arr {
                let folder = f as! MCOIMAPFolder
                let path = folder.path.replacingOccurrences(of: "[Gmail]", with: "").trimLeadingSlash
                if path != "" {
                    menu.append(path)
                    folders.append(folder)
                }
            }
            resolve(FetchFoldersRes(folders: folders, menu: menu))
        }
    }}

    func fetchMsg(message: MCOIMAPMessage, folder: String) -> Promise<Data> { return Promise { resolve, reject in
        self.getImapSess()
            .fetchMessageOperation(withFolder: folder, uid: message.uid)
            .start(self.finalize("fetchMsg", resolve, reject, retry: { self.fetchMsg(message: message, folder: folder) }))
    }}

    private func fetchMsgs(folder: String, kind: ReqKind, uids: MCOIndexSet) -> Promise<[MCOIMAPMessage]> { return Promise { resolve, reject in
        let start = DispatchTime.now()
        self.getImapSess()
            .fetchMessagesOperation(withFolder: folder, requestKind: kind, uids: uids)
            .start { error, msgs, vanished in
                self.log("fetchMsgs", error: error, res: nil, start: start)
                guard self.retryAuthErrorNotNeeded(error, resolve, reject, retry: { self.fetchMsgs(folder: folder, kind: kind, uids: uids) }) else { return }
                let messages = msgs as? [MCOIMAPMessage]
                if messages == nil {
                    reject(Errors.valueError("fetchMsgs messages == nil"))
                } else {
                    resolve(messages!)
                }
            }
    }}

    func markAsRead(message: MCOIMAPMessage, folder: String) -> Promise<VOID> { return Promise<VOID> { resolve, reject in
        self.getImapSess()
            .storeFlagsOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(message.uid)), kind: MCOIMAPStoreFlagsRequestKind.add, flags: message.flags)
            .start(self.finalizeVoid("markAsRead", resolve, reject, retry: { self.markAsRead(message: message, folder: folder) }))
    }}

    func moveMsg(msg: MCOIMAPMessage, folder: String, destFolder: String) -> Promise<VOID> { return Promise<VOID> { resolve, reject in
        self.getImapSess()
            .copyMessagesOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(msg.uid)), destFolder: destFolder)
            .start(self.finalizeAsVoid("moveMsg", resolve, reject, retry: { self.moveMsg(msg: msg, folder: folder, destFolder: destFolder) }))
    }}

    func pushUpdatedMsgFlags(msg: MCOIMAPMessage, folder: String) -> Promise<VOID> { return Promise<VOID> { resolve, reject in
        self.getImapSess()
            .storeFlagsOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(msg.uid)), kind: MCOIMAPStoreFlagsRequestKind.add, flags: msg.flags)
            .start(self.finalizeVoid("updateMsgFlags", resolve, reject, retry: { self.pushUpdatedMsgFlags(msg: msg, folder: folder) }))
    }}

    func sendMail(mime: Data) -> Promise<VOID> { return Promise<VOID> { resolve, reject in
        self.getSmtpSess()
            .sendOperation(with: mime)
            .start(self.finalizeVoid("send", resolve, reject, retry: { self.sendMail(mime: mime) }))
    }}

    private func searchExpression(folder: String, expression: MCOIMAPSearchExpression) -> Promise<MCOIndexSet> { return Promise<MCOIndexSet> { resolve, reject in
        self.getImapSess()
            .searchExpressionOperation(withFolder: folder, expression: expression)
            .start(self.finalize("searchExpression", resolve, reject, retry: { self.searchExpression(folder: folder, expression: expression) }))
    }}

    private func fetchMsgAtt(msgUid: UInt32, part: MCOIMAPPart) -> Promise<Data> { return Promise<Data> { resolve, reject in
        self.getImapSess()
            .fetchMessageAttachmentOperation(withFolder: self.inboxFolder, uid: msgUid, partID: part.partID, encoding: part.encoding)
            .start(self.finalize("fetchMsgAtt", resolve, reject, retry: { self.fetchMsgAtt(msgUid: msgUid, part: part) }))
    }}

    func searchBackups(email: String) -> Promise<Data> { return Promise<Data>.valueReturning {
        var exprSubjects: MCOIMAPSearchExpression? = nil;
        for subject in EmailConstant.recoverAccountSearchSubject {
            let exprSubject = MCOIMAPSearchExpression.searchSubject(subject)
            exprSubjects = exprSubjects == nil ? exprSubject : MCOIMAPSearchExpression.searchOr(exprSubjects, other: exprSubject)
        }
        let exprFromToMe = MCOIMAPSearchExpression.searchOr(MCOIMAPSearchExpression.search(from: email), other: MCOIMAPSearchExpression.search(to: email))
        let backupSearchExpr = MCOIMAPSearchExpression.searchAnd(exprFromToMe, other: exprSubjects)
        let searchRes = try await(self.searchExpression(folder: self.inboxFolder, expression: backupSearchExpr!))
        let requestKind = ReqKind.headers.rawValue | ReqKind.structure.rawValue | ReqKind.internalDate.rawValue | ReqKind.headerSubject.rawValue | ReqKind.flags.rawValue
        let msgs = try await(self.fetchMsgs(folder: self.inboxFolder, kind: ReqKind(rawValue: requestKind), uids: searchRes))
        var data = Data()
        for msg in msgs {
            for attPart in msg.attachments() as! [MCOIMAPPart] {
                data += try await(self.fetchMsgAtt(msgUid: msg.uid, part: attPart))
                data += [10] // newline
            }
        }
        return data
    }}

    private func log(_ op: String, error: Error?, res: Any?, start: DispatchTime) {
        let errStr = error != nil ? "\(error!)" : "ok"
        var resStr = "Unknown"
        if res == nil {
            resStr = "nil" 
        } else if res is Data {
            let data = res as! Data
            resStr = "Data[\(res != nil ? (data.count < 1204 ? "\(data.count)" : "\(data.count / 1024)k") : "-")]"
        } else if res as? NSArray != nil {
            resStr = "Array[\((res as! NSArray).count)]"
        } else if res as? FetchFoldersRes != nil {
            resStr = "FetchFoldersRes[\((res as! FetchFoldersRes).folders.count)]"
        }
        print("IMAP \(op) -> \(errStr) \(resStr) \(start.millisecondsSince())ms")
    }

    private func finalize<T>(_ op: String, _ resolve: @escaping (T) -> Void, _ reject: @escaping (Error) -> Void, retry: @escaping () -> Promise<T>) -> (Error?, T?) -> Void {
        let start = DispatchTime.now()
        return { (error, res) in
            self.log(op, error: error, res: res, start: start)
            guard self.retryAuthErrorNotNeeded(error, resolve, reject, retry: retry) else { return }
            error == nil ? resolve(res!) : reject(error!)
        }
    }

    private func finalizeVoid(_ op: String, _ resolve: @escaping (VOID) -> Void, _ reject: @escaping (Error) -> Void, retry: @escaping () -> Promise<VOID>) -> (Error?) -> Void {
        let start = DispatchTime.now()
        return { (error) in
            self.log(op, error: error, res: nil, start: start)
            guard self.retryAuthErrorNotNeeded(error, resolve, reject, retry: retry) else { return }
            error == nil ? resolve(VOID()) : reject(error!)

        }
    }

    private func finalizeAsVoid(_ op: String, _ resolve: @escaping (VOID) -> Void, _ reject: @escaping (Error) -> Void, retry: @escaping () -> Promise<VOID>) -> (Error?, Any?) -> Void {
        let start = DispatchTime.now()
        return { (error, discardable) in
            self.log(op, error: error, res: nil, start: start)
            guard self.retryAuthErrorNotNeeded(error, resolve, reject, retry: retry) else { return }
            error == nil ? resolve(VOID()) : reject(error!)
        }
    }

    // must be always called with `guard retryAuthErrorNotNeeded else { return }`
    private func retryAuthErrorNotNeeded<T>(_ err: Error?, _ resolve: @escaping (T) -> Void, _ reject: @escaping (Error) -> Void, retry promise: @escaping () -> Promise<T>) -> Bool {
        if err == nil {
            self.lastErr = nil;
            return true // no need to retry
        } else {
            if (err! as NSError).code == MCOErrorCode.authentication.rawValue && self.lastErr != MCOErrorCode.authentication { // avoiding infinite retry loop
                let start = DispatchTime.now()
                GoogleApi.instance.renewAccessToken().then { accessToken in
                    let _ = self.getImapSess(newAccessToken: accessToken) // use the new token
                    let _ = self.getSmtpSess(newAccessToken: accessToken) // use the new token
                    self.log("renewAccessToken (next will retry original req)", error: nil, res: "<accessToken>", start: start)
                    promise().then(resolve).catch(reject)
                }.catch { error in
                    self.log("renewAccessToken", error: error, res: nil, start: start)
                    reject(error)
                }
                self.lastErr = MCOErrorCode(rawValue: (err! as NSError).code)
                return false; // need to retry
            } else {
                reject(err!)
                self.lastErr = MCOErrorCode(rawValue: (err! as NSError).code)
                return true // no need to retry
            }
        }
    }

    struct FetchFoldersRes {
        let folders: [MCOIMAPFolder]
        let menu: [String]
    }

}
