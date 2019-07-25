//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import Promises

class EmailProvider: NSObject {

    static let sharedInstance = EmailProvider()
    var isLoading = false
    var totalNumberOfInboxMessages: Int32 = 0
    var messages = [MCOIMAPMessage]()
    let inboxFolder = "INBOX"

    struct EmptyError: Error {}
    
    func imapSession() -> MCOIMAPSession {
        let s = MCOIMAPSession()
        s.hostname = "imap.gmail.com"
        s.port = 993
        s.connectionType = MCOConnectionType.TLS
        s.authType = MCOAuthType.xoAuth2
        s.username = GoogleApi.instance.getEmail()
        s.password = nil
        s.oAuth2Token = GoogleApi.instance.getAccessToken()
        s.authType = MCOAuthType.xoAuth2
        s.connectionType = MCOConnectionType.TLS
        s.connectionLogger = { (connectionID, type, data) in
            if data != nil {
                if let string = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) {
                    NSLog("Connectionlogger: \(string)")
                }
            }
        }
        return s
    }

    func smptSession() -> MCOSMTPSession {
        let s = MCOSMTPSession()
        s.hostname = "smtp.gmail.com"
        s.port = 465
        s.connectionType = MCOConnectionType.TLS
        s.authType = MCOAuthType.xoAuth2
        s.username = GoogleApi.instance.getEmail()
        s.password = nil
        s.oAuth2Token = GoogleApi.instance.getAccessToken()
        s.connectionLogger = { (connectionID, type, data) in
            if data != nil {
                if let string = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) {
                    NSLog("Connectionlogger: \(string)")
                }
            }
        }
        return s
    }

    func fetchLastMessages(nMessage: Int, folderName: String, callback: @escaping ((_ emails: [Any]?, _ error: Error?) -> Void)) {
        self.isLoading = true
        let requestKind = MCOIMAPMessagesRequestKind.headers.rawValue | MCOIMAPMessagesRequestKind.structure.rawValue | MCOIMAPMessagesRequestKind.internalDate.rawValue | MCOIMAPMessagesRequestKind.headerSubject.rawValue | MCOIMAPMessagesRequestKind.flags.rawValue
        imapSession().folderInfoOperation(folderName)?.start({ (error: Error?, folderInfor: MCOIMAPFolderInfo?) in
            if error == nil {
                let totalNumberOfMessagesDidChange = Int32(self.totalNumberOfInboxMessages) != folderInfor?.messageCount
                self.totalNumberOfInboxMessages = (folderInfor?.messageCount)!
                var numberOfMessagesToLoad = min(self.totalNumberOfInboxMessages, Int32(nMessage))
                if numberOfMessagesToLoad == 0 {
                    self.isLoading = false
                    callback(nil, nil)
                    return
                }
                let fetchRange: MCORange
                // If total number of messages did not change since last fetch,
                // assume nothing was deleted since our last fetch and just
                // fetch what we don't have
                if (!totalNumberOfMessagesDidChange && self.messages.count > 0) {
                    numberOfMessagesToLoad -= Int32(self.messages.count)
                    fetchRange = MCORangeMake(UInt64(self.totalNumberOfInboxMessages - Int32(self.messages.count) - (numberOfMessagesToLoad - 1)), UInt64(numberOfMessagesToLoad - 1))
                } else { // Else just fetch the last N messages
                    fetchRange = MCORangeMake(UInt64(self.totalNumberOfInboxMessages - (numberOfMessagesToLoad - 1)), (UInt64(numberOfMessagesToLoad - 1)))
                }
                let imapMessagesFetchOp = self.imapSession().fetchMessagesByNumberOperation(withFolder: folderName, requestKind: MCOIMAPMessagesRequestKind(rawValue: requestKind), numbers: MCOIndexSet(range: fetchRange))
                imapMessagesFetchOp?.start({ (error: Error?, messages: [Any]?, vanishedMessages: MCOIndexSet?) in
                    self.isLoading = false
                    if error == nil {
                        if let messages = messages as? [MCOIMAPMessage] {
                            self.messages.append(contentsOf: messages)
                            self.messages = self.messages.sorted {
                                $0.header.date > $1.header.date
                            }
                        }
                        callback(self.messages, nil)
                    } else {
                        callback(nil, error)
                    }
                })
            } else {
                callback(nil, error)
            }
        })
    }

    func fetchFolder(callback: @escaping ((_ folders: [MCOIMAPFolder]?, _ menuArray: [String]?, _ error: Error?) -> Void)) {
        imapSession().fetchAllFoldersOperation().start { (error, res) in
            var menuArray = [String]()
            var arrFolder = [MCOIMAPFolder]()
            if res != nil {
                if let arr = res as NSArray? {
                    for f in arr {
                        let folder = f as! MCOIMAPFolder
                        let p = folder.path.replacingOccurrences(of: "[Gmail]", with: "")
                        let path = p.replacingOccurrences(of: "/", with: "")
                        if path != "" {
                            menuArray.append(path)
                            arrFolder.append(folder)
                        }
                        callback(arrFolder, menuArray, nil)
                    }
                }
            } else {
                callback(nil, nil, error)
            }
        }
    }

    func fetchMessageBody(message: MCOIMAPMessage, folder: String) -> Promise<Data> { return Promise { resolve, reject in
        self.imapSession().fetchMessageOperation(withFolder: folder, uid: message.uid)?.start { error, data in
            // todo - see if I can just pass `data` instead of `MCOMessageParser(data: data).data()`
            data != nil ? resolve(MCOMessageParser(data: data).data()) : reject(error ?? EmptyError())
        }
    }}

    func markAsRead(message: MCOIMAPMessage, folder: String) {
        imapSession().storeFlagsOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(message.uid)), kind: MCOIMAPStoreFlagsRequestKind.add, flags: message.flags)?.start({ (error) in })
    }

    func markAsTrashMessage(message: MCOIMAPMessage, folder: String, destFolder: String, callback: @escaping ((_ error: Error?) -> Void)) {
        imapSession().copyMessagesOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(message.uid)), destFolder: destFolder)?.start({ (error, response) in
            callback(error)
        })
    }

    func deleteMessage(message: MCOIMAPMessage, folder: String, callback: @escaping ((_ error: Error?) -> Void)) {
        imapSession().storeFlagsOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(message.uid)), kind: MCOIMAPStoreFlagsRequestKind.add, flags: message.flags)?.start(callback)
    }

    func sendMail(mime: Data) -> Promise<VOID> { return Promise<VOID> { (resolve: @escaping (VOID) -> Void, reject: @escaping (Error) -> Void) in
        self.smptSession().sendOperation(with: mime)?.start { e in e != nil ? reject(e!) : resolve(VOID())}
    }}

    func expungeToDelete(folder: String, callback: @escaping ((_ error: Error?) -> Void)) {
        imapSession().expungeOperation(folder)?.start(callback)
    }

    func searchBackup(email: String, callback: @escaping ((_ rawArmoredKey: String?, _ error: Error?) -> Void)) {
        self.isLoading = true
        var exprSubjects: MCOIMAPSearchExpression? = nil;
        for subject in EmailConstant.recoverAccountSearchSubject {
            let exprSubject = MCOIMAPSearchExpression.searchSubject(subject)
            exprSubjects = exprSubjects == nil ? exprSubject : MCOIMAPSearchExpression.searchOr(exprSubjects, other: exprSubject)
        }
        let exprFromToMe = MCOIMAPSearchExpression.searchOr(MCOIMAPSearchExpression.search(from: email), other: MCOIMAPSearchExpression.search(to: email))
        let backupSearchExpr = MCOIMAPSearchExpression.searchAnd(exprFromToMe, other: exprSubjects)
        imapSession().searchExpressionOperation(withFolder: self.inboxFolder, expression: backupSearchExpr)?.start({ (error: Error?, index: MCOIndexSet?) in
            guard error == nil else {
                callback(nil, error)
                return
            }
            let requestKind = MCOIMAPMessagesRequestKind.headers.rawValue | MCOIMAPMessagesRequestKind.structure.rawValue | MCOIMAPMessagesRequestKind.internalDate.rawValue | MCOIMAPMessagesRequestKind.headerSubject.rawValue | MCOIMAPMessagesRequestKind.flags.rawValue
            let imapMessagesFetchOp = self.imapSession().fetchMessagesOperation(withFolder: self.inboxFolder, requestKind: MCOIMAPMessagesRequestKind(rawValue: requestKind), uids: index)
            imapMessagesFetchOp?.start({ (error: Error?, messages: [Any]?, vanishedMessages: MCOIndexSet?) in
                guard error == nil else {
                    callback(nil, error)
                    return
                }
                guard var messages = messages as? [MCOIMAPMessage] else {
                    callback(nil, nil)
                    return
                }
                guard messages.count > 0 else {
                    callback(nil, nil)
                    return
                }
                messages = messages.sorted { // Download attachment of latest email
                    $0.header.date > $1.header.date
                }
                let message = messages[0]
                guard let attachments = message.attachments() else {
                    callback(nil, nil)
                    return
                }
                guard attachments.count > 0 else {
                    callback(nil, nil)
                    return
                }
                self.messages = self.messages.sorted {
                    $0.header.date > $1.header.date
                }
                let part = attachments[0] as! MCOIMAPPart
                let imapAttachmentFetchOp = self.imapSession().fetchMessageAttachmentOperation(withFolder: self.inboxFolder, uid: message.uid, partID: part.partID, encoding: part.encoding)
                imapAttachmentFetchOp?.start({ (error: Error?, data: Data?) in
                    if data != nil {
                        let decodedString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                        callback(decodedString! as String, nil)
                    } else {
                        callback(nil, error)
                    }
                })
            })
        })
    }
}
