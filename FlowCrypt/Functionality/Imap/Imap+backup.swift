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
    func searchBackups(for email: String) -> Promise<Data>
}

extension Imap: BackupProvider {
    func searchBackups(for email: String) -> Promise<Data> {
        return Promise { [weak self] () -> Data in
            guard let self = self else { throw AppErr.nilSelf }
            var folderPaths = try await(self.fetchFolders())
                .folders
                .compactMap { $0.path }

            if folderPaths.isEmpty {
                throw AppErr.unexpected("Error while fetching folders")
            }

            if folderPaths.contains(GeneralConstants.Global.gmailAllMailPath) {
                folderPaths = [GeneralConstants.Global.gmailAllMailPath]
            } else if let inbox = folderPaths.first(where: { $0.caseInsensitiveCompare("inbox") == .orderedSame }) {
                folderPaths = [inbox]
            }


            let searchExpr = self.createSearchBackupExpression(for: email)

            let uidsForFolders = try folderPaths.compactMap { folder -> UidsContext in
                let uids = try await(self.fetchUids(folder: folder, expr: searchExpr))
                return UidsContext(path: folder, uids: uids)
            }

            if uidsForFolders.isEmpty {
                throw AppErr.unexpected("Error while fetching uids")
            }

            let messageContexts = try uidsForFolders.flatMap { uidsContext -> [MsgContext] in
                let msgs = try await(self.fetchMessagesIn(folder: uidsContext.path, uids: uidsContext.uids))
                return msgs.map { msg in MsgContext(path: uidsContext.path, msg: msg) }
            }

            if messageContexts.isEmpty {
                throw AppErr.unexpected("Error while fetching messages")
            }

            let attContext = messageContexts.flatMap { msgContext -> [AttContext] in
                guard let parts = msgContext.msg.attachments() as? [MCOIMAPPart] else { assertionFailure(); return [] }
                return parts.map { part in AttContext(path: msgContext.path, msg: msgContext.msg, part: part) }
            }

            if attContext.isEmpty {
                throw AppErr.unexpected("Error while fetching attributes")
            }

            let dataArr = try attContext.map { attContext -> Data in
                try await(self.fetchMsgAttribute(
                    in: attContext.path,
                    msgUid: attContext.msg.uid,
                    part: attContext.part)
                ) + [10] // newline
            }

            return Data.joined(dataArr)
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
