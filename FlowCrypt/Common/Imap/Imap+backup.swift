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
            guard let searchExpr = self.createSearchBackupExpression() else {
                throw AppErr.general("could not create search expression")
            }
            var folderPaths = try await(self.fetchFolders()).folders
                .compactMap { $0.path }
                .compactMap { (path: String) -> String? in
                    path.isEmpty || path == Constants.Global.gmailRootPath
                        ? nil : path
                }
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
            self.getImapSess()
                .fetchMessageAttachmentOperation(withFolder: folder, uid: msgUid, partID: part.partID, encoding: part.encoding)
                .start(self.finalize("fetchMsgAtt", resolve, reject, retry: {
                    self.fetchMsgAttribute(in: folder, msgUid: msgUid, part: part)
                }))
        }
    }

    private func subjectsExpr() -> MCOIMAPSearchExpression? {
        let expressions = Constants.EmailConstant
            .recoverAccountSearchSubject
            .compactMap { MCOIMAPSearchExpression.searchSubject($0) }
        
        guard let expression = helper.createSearchExpressions(from: expressions) else {
            return nil
        }
        
        return expression
    }

    private func createSearchBackupExpression() -> MCOIMAPSearchExpression? {
        guard let expression = subjectsExpr() else { return nil }
        
        let fromToExpr = MCOIMAPSearchExpression.searchAnd(
            MCOIMAPSearchExpression.search(from: email),
            other: MCOIMAPSearchExpression.search(to: email)
        )
        
        return MCOIMAPSearchExpression.searchAnd(fromToExpr, other: expression)
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
