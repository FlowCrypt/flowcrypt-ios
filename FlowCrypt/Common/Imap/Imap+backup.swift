//
//  Imap+backup.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

@available(*, deprecated, message: "Needs to be refactored")
extension Imap {
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

    private func fetchMsgs(folder: String, kind: ReqKind, uids: MCOIndexSet) -> Promise<[MCOIMAPMessage]> { return Promise { resolve, reject in
        let start = DispatchTime.now()
        guard uids.count() > 0 else {
            log("fetchMsgs_empty", error: nil, res: [], start: start)
            resolve([]) // attempting to fetch an empty set of uids would cause IMAP error
            return
        }
        self.getImapSess()?
            .fetchMessagesOperation(withFolder: folder, requestKind: kind, uids: uids)
            .start { error, msgs, vanished in
                log("fetchMsgs", error: error, res: nil, start: start)
                guard self.retryAuthErrorNotNeeded("fetchMsgs", error, resolve, reject, retry: { self.fetchMsgs(folder: folder, kind: kind, uids: uids) }) else { return }
                let messages = msgs as? [MCOIMAPMessage]

                if let messages = messages {
                    resolve(messages)
                } else {
                    reject(Errors.valueError("fetchMsgs messages == nil"))
                }
        }
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
        let requestKind = DefaultMessageKindProvider().imapMessagesRequestKind

        let msgs = try await(self.fetchMsgs(folder: self.inboxFolder, kind: requestKind, uids: searchRes))
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
}

