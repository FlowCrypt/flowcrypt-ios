//
//  Imap+backup.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
import Promises

enum BackupError: Error {
    /// "Error while fetching folders" no folders on account
    case missedFolders
    /// "Error while fetching uids"
    case missedUIDS
    /// "Error while fetching messages"
    case missedMessages
    /// "Error while fetching attributes"
    case missedAttributes
}

extension Imap: BackupProvider {
    func searchBackups(for email: String) -> Promise<Data> {
        Promise { [weak self] () -> Data in
            guard let self = self else { throw AppErr.nilSelf }
            var folderPaths = try awaitPromise(self.fetchFolders())
                .map(\.path)

            guard folderPaths.isNotEmpty else {
                throw BackupError.missedFolders
            }

            if let inbox = folderPaths.firstCaseInsensitive("inbox") {
                folderPaths = [inbox]
            }

            let searchExpr = self.createSearchBackupExpression(for: email)

            let uidsForFolders = try folderPaths.compactMap { folder -> UidsContext in
                let uids = try awaitPromise(self.fetchUids(folder: folder, expr: searchExpr))
                return UidsContext(path: folder, uids: uids)
            }

            guard uidsForFolders.isNotEmpty else {
                throw BackupError.missedUIDS
            }

            let messageContexts = try uidsForFolders.flatMap { uidsContext -> [MsgContext] in
                let msgs = try awaitPromise(self.fetchMessagesIn(folder: uidsContext.path, uids: uidsContext.uids))
                return msgs.map { msg in MsgContext(path: uidsContext.path, msg: msg) }
            }

            // in case there are no messages return empty data
            // user will be prompted to create new backup
            guard messageContexts.isNotEmpty else {
                return Data()
            }

            let attContext = messageContexts.flatMap { msgContext -> [AttContext] in
                guard let parts = msgContext.msg.attachments() as? [MCOIMAPPart] else { assertionFailure(); return [] }
                return parts.map { part in AttContext(path: msgContext.path, msg: msgContext.msg, part: part) }
            }

            // in case there are no attachments return empty data
            guard attContext.isNotEmpty else {
                return Data()
            }

            let dataArr = try attContext.map { attContext -> Data in
                try awaitPromise(self.fetchMsgAttribute(
                    in: attContext.path,
                    msgUid: attContext.msg.uid,
                    part: attContext.part
                )
                ) + [10] // newline
            }

            return dataArr.joined
        }
    }

    private func fetchMsgAttribute(in folder: String, msgUid: UInt32, part: MCOIMAPPart) -> Promise<Data> {
        Promise<Data> { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }
            self.imapSess?
                .fetchMessageAttachmentOperation(
                    withFolder: folder,
                    uid: msgUid,
                    partID: part.partID,
                    encoding: part.encoding
                )
                .start(self.finalize("fetchMsgAtt", resolve, reject, retry: {
                    self.fetchMsgAttribute(in: folder, msgUid: msgUid, part: part)
                }))
        }
    }

    private func subjectsExpr() -> MCOIMAPSearchExpression {
        let expressions = GeneralConstants.EmailConstant
            .recoverAccountSearchSubject
            .compactMap { MCOIMAPSearchExpression.searchSubject($0) }
        guard let expression = helper.createSearchExpressions(from: expressions) else {
            fatalError("could not create search expression")
        }
        return expression
    }

    private func createSearchBackupExpression(for email: String) -> MCOIMAPSearchExpression {
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
