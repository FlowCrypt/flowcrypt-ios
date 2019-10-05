//
//  Imap+backup.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

protocol BackupProvider {
    func searchBackups() -> Promise<Data>
}

extension Imap: BackupProvider {
    func searchBackups() -> Promise<Data> {
        return Promise { [weak self] () -> Data in
            guard let self = self else { throw AppErr.nilSelf }
            let searchExpr = self.createSearchBackupExpression()
            var folderPaths = try await(self.fetchFolders()).folders
                .compactMap { $0.path }
                .compactMap { (path: String) -> String? in path.isEmpty || path == Constants.Global.gmailRootPath ? nil : path }
            if folderPaths.contains(Constants.Global.gmailAllMailPath) {
                folderPaths = [Constants.Global.gmailAllMailPath] // On Gmail, no need to cycle through each folder
            }
            let dataArr = try folderPaths
                .compactMap { folder in UidsContext(path: folder, uids: try await(self.fetchUids(folder: folder, expr: searchExpr))) }
                .filter { $0.uids.count() > 0 }
                .flatMap { uidsContext -> [MsgContext] in
                    let msgs = try await(self.fetchMessagesIn(folder: uidsContext.path, uids: uidsContext.uids))
                    return msgs.map { msg in MsgContext(path: uidsContext.path, msg: msg) }
                }
                .flatMap { msgContext -> [AttContext] in
                    guard let parts = msgContext.msg.attachments() as? [MCOIMAPPart] else { assertionFailure(); return [] }
                    return parts.map { part in AttContext(path: msgContext.path, msg: msgContext.msg, part: part) }
                }
                .map { attContext -> Data in
                    try await(self.fetchMsgAttribute(in: attContext.path, msgUid: attContext.msg.uid, part: attContext.part)) + [10] // newline
                }
            return Data.joined(dataArr)
        }
    }

    // todo - should be moved to a general Imap class or extension
    private func fetchMsgAttribute(in folder: String, msgUid: UInt32, part: MCOIMAPPart) -> Promise<Data> {
        return Promise<Data> { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }
            self.getImapSess()?
                .fetchMessageAttachmentOperation(withFolder: folder, uid: msgUid, partID: part.partID, encoding: part.encoding)
                .start(self.finalize("fetchMsgAtt", resolve, reject, retry: {
                    self.fetchMsgAttribute(in: folder, msgUid: msgUid, part: part)
                }))
        }
    }

    // todo - should be moved to a general Imap class or extension
    private func fetchMessagesIn(folder: String, uids: MCOIndexSet) -> Promise<[MCOIMAPMessage]> {
        return Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            let start = DispatchTime.now()
            let kind = DefaultMessageKindProvider().imapMessagesRequestKind

            guard uids.count() > 0 else {
                log("fetchMsgs_empty", error: nil, res: [], start: start)
                resolve([]) // attempting to fetch an empty set of uids would cause IMAP error
                return
            }

            let messages = try await(self.fetchMessage(in: folder, kind: kind, uids: uids))
            resolve(messages)
        }
    }

    // todo - should be moved to a general Imap class or extension
    private func fetchMessage(in folder: String, kind: MCOIMAPMessagesRequestKind, uids: MCOIndexSet) -> Promise<[MCOIMAPMessage]> {
        return Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            self.getImapSess()?
                .fetchMessagesOperation(withFolder: folder, requestKind: kind, uids: uids)?
                .start { error, msgs, _ in
                    guard self.retryAuthErrorNotNeeded("fetchMsgs", error, resolve, reject, retry: {
                        self.fetchMessage(in: folder, kind: kind, uids: uids)
                    }) else { return }

                    if let messages = msgs as? [MCOIMAPMessage] {
                        return resolve(messages)
                    } else {
                        reject(AppErr.cast("msgs as? [MCOIMAPMessage]"))
                    }
                }
        }
    }

    // todo - should be moved to a general Imap class or extension
    private func fetchUids(folder: String, expr: MCOIMAPSearchExpression) -> Promise<MCOIndexSet> {
        return Promise<MCOIndexSet> { resolve, reject in
            self.getImapSess()?
                .searchExpressionOperation(withFolder: folder, expression: expr)
                .start(self.finalize("searchExpression", resolve, reject, retry: { self.fetchUids(folder: folder, expr: expr) }))
        }
    }

    private func subjectsExpr() -> MCOIMAPSearchExpression {
        var resultArray = Constants.EmailConstant.recoverAccountSearchSubject.compactMap { MCOIMAPSearchExpression.searchSubject($0) }
        while resultArray.count > 1 {
            resultArray = resultArray
                .chunked(2)
                .compactMap { (chunk) -> MCOIMAPSearchExpression? in
                    guard let firstSearchExp = chunk.first else { return nil }
                    guard let secondSearchExp = chunk[safe: 1] else { return firstSearchExp }
                    return MCOIMAPSearchExpression.searchOr(firstSearchExp, other: secondSearchExp)
                }
        }
        return resultArray.first! // app should crash if we got this wrong
    }

    private func createSearchBackupExpression() -> MCOIMAPSearchExpression {
        let fromToExpr = MCOIMAPSearchExpression.searchAnd(
            MCOIMAPSearchExpression.search(from: email),
            other: MCOIMAPSearchExpression.search(to: email)
        )
        return MCOIMAPSearchExpression.searchAnd(fromToExpr, other: subjectsExpr())
    }
}

private struct UidsContext {
    let path: String
    let uids: MCOIndexSet
}

private struct MsgContext {
    let path: String
    let msg: MCOIMAPMessage
}

private struct AttContext {
    let path: String
    let msg: MCOIMAPMessage
    let part: MCOIMAPPart
}
