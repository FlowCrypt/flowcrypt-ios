//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import Promises

enum ImapError: Error {
    case general
}

final class Imap {
    private init() { }

    static let instance = Imap()
    
    var totalNumberOfInboxMsgs: Int32 = 0
    var messages = [MCOIMAPMessage]()
    let inboxFolder = "INBOX"
    var imapSess: MCOIMAPSession?
    var smtpSess: MCOSMTPSession?

    struct EmptyError: Error {}
    private typealias ReqKind = MCOIMAPMessagesRequestKind
    private typealias Err = MCOErrorCode
    private var lastErr: [String: Err] = []

    func getImapSess(newAccessToken: String? = nil) -> MCOIMAPSession? {
        if imapSess == nil || newAccessToken != nil {
            print("IMAP: creating a new session")
            let imapSess = MCOIMAPSession()
            imapSess.hostname = "imap.gmail.com"
            imapSess.port = 993
            imapSess.connectionType = MCOConnectionType.TLS
            imapSess.authType = MCOAuthType.xoAuth2
            imapSess.username = GoogleApi.instance.getEmail()
            imapSess.password = nil
            imapSess.oAuth2Token = newAccessToken ?? GoogleApi.instance.getAccessToken()
            imapSess.authType = MCOAuthType.xoAuth2
            imapSess.connectionType = MCOConnectionType.TLS
            self.imapSess = imapSess
//            imapSess!.connectionLogger = {(connectionID, type, data) in
//                if data != nil {
//                    if let string = String(data: data!, encoding: String.Encoding.utf8) {
//                        print("IMAP:\(type):\(string)")
//                    }
//                }
//            }
        }
        return imapSess
    }

    func getSmtpSess(newAccessToken: String? = nil) -> MCOSMTPSession? {
        if smtpSess == nil || newAccessToken != nil {
            print("SMTP: creating a new session")
            let smtpSess = MCOSMTPSession()
            smtpSess.hostname = "smtp.gmail.com"
            smtpSess.port = 465
            smtpSess.connectionType = MCOConnectionType.TLS
            smtpSess.authType = MCOAuthType.xoAuth2
            smtpSess.username = GoogleApi.instance.getEmail()
            smtpSess.password = nil
            smtpSess.oAuth2Token = newAccessToken ?? GoogleApi.instance.getAccessToken()
            self.smtpSess = smtpSess
        }
        return smtpSess
    }

    private func fetchFolderInfo(_ folder: String) -> Promise<MCOIMAPFolderInfo> { return Promise<MCOIMAPFolderInfo> { resolve, reject in
        self.getImapSess()?
            .folderInfoOperation(folder)
            .start(self.finalize("fetchFolderInfo", resolve, reject, retry: { self.fetchFolderInfo(folder) }))
    }}

    private func fetchMsgsByNumber(_ folder: String, kind: MCOIMAPMessagesRequestKind, range: MCORange) -> Promise<[MCOIMAPMessage]> { return Promise<[MCOIMAPMessage]> { resolve, reject in
        let start = DispatchTime.now()
        self.getImapSess()?
            .fetchMessagesByNumberOperation(withFolder: folder, requestKind: kind, numbers: MCOIndexSet(range: range))
            .start { error, msgs, vanishedMsgs in
                self.log("fetchMsgsByNumber", error: error, res: nil, start: start)
                guard self.retryAuthErrorNotNeeded("fetchMsgsByNumber", error, resolve, reject, retry: { self.fetchMsgsByNumber(folder, kind: kind, range: range) }) else { return }
                if let error = error {
                    reject(error)
                } else {
                    guard let messages = msgs as? [MCOIMAPMessage] else {
                        reject(Errors.valueError("fetchMessagesByNumber messages == nil"))
                        return
                    }
                    self.messages.append(contentsOf: messages)
                    self.messages.sort { $0.header.date > $1.header.date }
                    resolve(self.messages)
                }
            }
    }}

    func fetchLastMsgs(count: Int, folder: String) -> Promise<[MCOIMAPMessage]> { return Promise<[MCOIMAPMessage]>.valueReturning {
        let kind = ReqKind.headers.rawValue | ReqKind.structure.rawValue | ReqKind.internalDate.rawValue | ReqKind.headerSubject.rawValue | ReqKind.flags.rawValue
        let folderInfo = try await(self.fetchFolderInfo(folder))
        let didTotalNumberOfMsgsChange = Int32(self.totalNumberOfInboxMsgs) != folderInfo.messageCount
        self.messages.removeAll()
        self.totalNumberOfInboxMsgs = folderInfo.messageCount
        var numberOfMsgsToLoad = min(self.totalNumberOfInboxMsgs, Int32(count))
        guard numberOfMsgsToLoad != 0 else { return [] }
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

    func fetchFolders() -> Promise<FoldersContext> { return Promise<FoldersContext> { resolve, reject in
        let start = DispatchTime.now()
        self.getImapSess()?.fetchAllFoldersOperation().start { (error, res) in
            self.log("fetchMsgs", error: error, res: res, start: start)
            guard self.retryAuthErrorNotNeeded("fetchLastMsgs", error, resolve, reject, retry: { self.fetchFolders() }) else { return }
            guard let arr = res as NSArray? else {
                reject(Errors.valueError("Response from fetchFolders not a NSArray, instead got \(String(describing: res))"))
                return;
            }
            var menu = [String]()
            var folders = [MCOIMAPFolder]()
            for f in arr {
                guard let folder = f as? MCOIMAPFolder else { return }

                let path = folder.path.replacingOccurrences(of: "[Gmail]", with: "").trimLeadingSlash
                if !path.isEmpty {
                    menu.append(path)
                    folders.append(folder)
                }
            }
            resolve(FoldersContext(folders: folders, menu: menu))
        }
    }}

    func fetchMsg(message: MCOIMAPMessage, folder: String) -> Promise<Data> { return Promise { resolve, reject in
        self.getImapSess()?
            .fetchMessageOperation(withFolder: folder, uid: message.uid)
            .start(self.finalize("fetchMsg", resolve, reject, retry: { self.fetchMsg(message: message, folder: folder) }))
    }}

    private func fetchMsgs(folder: String, kind: ReqKind, uids: MCOIndexSet) -> Promise<[MCOIMAPMessage]> { return Promise { resolve, reject in
        let start = DispatchTime.now()
        guard uids.count() > 0 else {
            self.log("fetchMsgs_empty", error: nil, res: [], start: start)
            resolve([]) // attempting to fetch an empty set of uids would cause IMAP error
            return
        }
        self.getImapSess()?
            .fetchMessagesOperation(withFolder: folder, requestKind: kind, uids: uids)
            .start { error, msgs, vanished in
                self.log("fetchMsgs", error: error, res: nil, start: start)
                guard self.retryAuthErrorNotNeeded("fetchMsgs", error, resolve, reject, retry: { self.fetchMsgs(folder: folder, kind: kind, uids: uids) }) else { return }
                let messages = msgs as? [MCOIMAPMessage]

                if let messages = messages {
                    resolve(messages)
                } else {
                    reject(Errors.valueError("fetchMsgs messages == nil"))
                }
            }
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

    private func searchExpression(folder: String, expression: MCOIMAPSearchExpression) -> Promise<MCOIndexSet> { return Promise<MCOIndexSet> { resolve, reject in
        self.getImapSess()?
            .searchExpressionOperation(withFolder: folder, expression: expression)
            .start(self.finalize("searchExpression", resolve, reject, retry: { self.searchExpression(folder: folder, expression: expression) }))
    }}

    private func fetchMsgAtt(msgUid: UInt32, part: MCOIMAPPart) -> Promise<Data> { return Promise<Data> { resolve, reject in
        self.getImapSess()?
            .fetchMessageAttachmentOperation(withFolder: self.inboxFolder, uid: msgUid, partID: part.partID, encoding: part.encoding)
            .start(self.finalize("fetchMsgAtt", resolve, reject, retry: { self.fetchMsgAtt(msgUid: msgUid, part: part) }))
    }}

    func searchBackups(email: String) -> Promise<Data> { return Promise<Data>.valueReturning {
        var exprSubjects: MCOIMAPSearchExpression? = nil
        for subject in EmailConstant.recoverAccountSearchSubject {
            let exprSubject = MCOIMAPSearchExpression.searchSubject(subject)
            exprSubjects = exprSubjects == nil ? exprSubject : MCOIMAPSearchExpression.searchOr(exprSubjects, other: exprSubject)
        }
        let exprFromToMe = MCOIMAPSearchExpression.searchOr(MCOIMAPSearchExpression.search(from: email), other: MCOIMAPSearchExpression.search(to: email))
        guard let backupSearchExpr = MCOIMAPSearchExpression.searchAnd(exprFromToMe, other: exprSubjects) else {
            assertionFailure()
            return Data()
        }
        let searchRes = try await(self.searchExpression(folder: self.inboxFolder, expression: backupSearchExpr))
        let requestKind = ReqKind.headers.rawValue | ReqKind.structure.rawValue | ReqKind.internalDate.rawValue | ReqKind.headerSubject.rawValue | ReqKind.flags.rawValue
        let msgs = try await(self.fetchMsgs(folder: self.inboxFolder, kind: ReqKind(rawValue: requestKind), uids: searchRes))
        var data = Data()
        for msg in msgs {
            guard let attachments = msg.attachments() as? [MCOIMAPPart] else { assertionFailure(); return Data() }
            for attPart in attachments {
                data += try await(self.fetchMsgAtt(msgUid: msg.uid, part: attPart))
                data += [10] // newline
            }
        }
        return data
    }}

    private func log(_ op: String, error: Error?, res: Any?, start: DispatchTime) {
        let errStr = error.map { "\($0)" } ?? ""
        var resStr = "Unknown"
        if res == nil {
            resStr = "nil" 
        } else if let data = res as? Data {
            resStr = "Data[\(res != nil ? (data.count < 1204 ? "\(data.count)" : "\(data.count / 1024)k") : "-")]"
        } else if let res = res as? NSArray {
            resStr = "Array[\(res.count)]"
        } else if let res = res as? FoldersContext {
            resStr = "FetchFoldersRes[\(res.folders.count)]"
        }
        print("IMAP \(op) -> \(errStr) \(resStr) \(start.millisecondsSince)ms")
    }

    private func finalize<T>(_ op: String, _ resolve: @escaping (T) -> Void, _ reject: @escaping (Error) -> Void, retry: @escaping () -> Promise<T>) -> (Error?, T?) -> Void {
        let start = DispatchTime.now()
        return { (error, res) in
            self.log(op, error: error, res: res, start: start)
            guard self.retryAuthErrorNotNeeded(op, error, resolve, reject, retry: retry) else { return }
            if let res = res {
                resolve(res)
            } else {
                reject(error ?? ImapError.general)
            }
        }
    }

    private func finalizeVoid(_ op: String, _ resolve: @escaping (VOID) -> Void, _ reject: @escaping (Error) -> Void, retry: @escaping () -> Promise<VOID>) -> (Error?) -> Void {
        let start = DispatchTime.now()
        return { (error) in
            self.log(op, error: error, res: nil, start: start)
            guard self.retryAuthErrorNotNeeded(op, error, resolve, reject, retry: retry) else { return }
            if let error = error {
                reject(error)
            } else {
                resolve(VOID())
            }
        }
    }

    private func finalizeAsVoid(_ op: String, _ resolve: @escaping (VOID) -> Void, _ reject: @escaping (Error) -> Void, retry: @escaping () -> Promise<VOID>) -> (Error?, Any?) -> Void {
        let start = DispatchTime.now()
        return { (error, discardable) in
            self.log(op, error: error, res: nil, start: start)
            guard self.retryAuthErrorNotNeeded(op, error, resolve, reject, retry: retry) else { return }
            if let error = error {
                reject(error)
            } else {
                resolve(VOID())
            }
        }
    }

    // must be always called with `guard retryAuthErrorNotNeeded else { return }`
    private func retryAuthErrorNotNeeded<T>(_ op: String, _ err: Error?, _ resolve: @escaping (T) -> Void, _ reject: @escaping (Error) -> Void, retry: @escaping () -> Promise<T>) -> Bool {
        if err == nil {
            self.lastErr.removeValue(forKey: op)
            return true // no need to retry
        } else {
            let debugId = Int.random(in: 1...Int.max)
            Imap.debug(1, "(\(debugId)|\(op)) new err retryAuthErrorNotNeeded, err=", value: err)
            Imap.debug(2, "(\(debugId)|\(op)) last err in retryAuthErrorNotNeeded lastErr=", value: self.lastErr[op])
            let start = DispatchTime.now()
            // also checking against lastErr below to avoid infinite retry loop
            if let e = err as NSError?, e.code == Err.authentication.rawValue, self.lastErr[op] != Err.authentication {
                Imap.debug(3, "(\(debugId)|\(op)) it's a retriable auth err, will call renewAccessToken")
                GoogleApi.instance.renewAccessToken().then { accessToken in
                    Imap.debug(4, "(\(debugId)|\(op)) got renewed access token")
                    let _ = self.getImapSess(newAccessToken: accessToken) // use the new token
                    let _ = self.getSmtpSess(newAccessToken: accessToken) // use the new token
                    Imap.debug(5, "(\(debugId)|\(op)) forced session refreshes")
                    self.log("renewAccessToken for \(op), will retry \(op)", error: nil, res: "<accessToken>", start: start)
                    retry().then(resolve).catch(reject)
                }.catch { error in
                    Imap.debug(6, "(\(debugId)|\(op)) error refreshing token", value: e)
                    self.log("renewAccessToken for \(op)", error: error, res: nil, start: start)
                    reject(error)
                }
                self.lastErr[op] = Err(rawValue: e.code)
                Imap.debug(7, "(\(debugId)|\(op)) just set lastErr to ", value: self.lastErr[op])
                Imap.debug(11, "(\(debugId)|\(op)) return=true (need to retry)")
                return false; // need to retry
            } else if let e = err as NSError?, e.code == Err.connection.rawValue, self.lastErr[op] != Err.connection {
                Imap.debug(13, "(\(debugId)|\(op)) it's a retriable conn err, clear sessions")
                self.imapSess = nil; // the connection has dropped, so it's probably ok to not officially "close" it
                self.smtpSess = nil; // but maybe there could be a cleaner way to dispose of the connection?
                self.lastErr[op] = Err(rawValue: e.code)
                Imap.debug(14, "(\(debugId)|\(op)) just set lastErr to ", value: self.lastErr[op])
                self.log("conn drop for \(op), cleared sessions, will retry \(op)", error: nil, res: nil, start: start)
                retry().then(resolve).catch(reject)
                Imap.debug(15, "(\(debugId)|\(op)) return=true (need to retry)")
                return false; // need to retry
            } else {
                Imap.debug(8, "(\(debugId)|\(op)) err not retriable, rejecting ", value: err)
                reject(err ?? ImapError.general)
                self.lastErr[op] = Err(rawValue: (err as NSError?)?.code ?? Constants.Global.generalError)
                Imap.debug(9, "(\(debugId)|\(op)) just set lastErr to ", value: self.lastErr[op])
                Imap.debug(12, "(\(debugId)|\(op)) return=true (no need to retry)")
                return true // no need to retry
            }
        }
    }

    public static func debug(_ id: Int, _ msg: String, value: Any? = nil) { // temporary function while we debug token refreshing
        // print("[Imap token debug \(id) - \(msg)] \(String(describing: value))")
    }

}

struct FoldersContext {
    let folders: [MCOIMAPFolder]
    let menu: [String]
}

enum MailDestination {
    enum Gmail {
        case trash

        var path: String {
            switch self {
            case .trash: return "[Gmail]/Trash"
            }
        }
    }
}
