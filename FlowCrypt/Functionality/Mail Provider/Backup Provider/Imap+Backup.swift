//
//  Imap+backup.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import MailCore

enum BackupError: Error {
    /// "Error while fetching folders" no folders on account
    case missingFolders
    /// "Error while fetching uids"
    case missingUIDS
    /// "Error while fetching messages"
    case missingMessages
    /// "Error while fetching attributes"
    case missingAttributes
}

extension Imap: BackupApiClient {
    func searchBackups(for email: String) async throws -> Data {
        var folderPaths = (try await fetchFolders()).map(\.path)

        guard folderPaths.isNotEmpty else {
            throw BackupError.missingFolders
        }

        if let inbox = folderPaths.firstCaseInsensitive("inbox") {
            folderPaths = [inbox]
        }

        let searchExpr = try createSearchBackupExpression(for: email)

        var uidsForFolders: [UidsContext] = []
        for folder in folderPaths {
            // parallelize? but it's just one IMAP connection anyway?
            let uids = try await fetchUids(folder: folder, expr: searchExpr)
            uidsForFolders.append(UidsContext(path: folder, uids: uids))
        }

        guard uidsForFolders.isNotEmpty else {
            throw BackupError.missingUIDS
        }

        var messageContexts: [MsgContext] = []
        for uidsContext in uidsForFolders {
            // parallelize? but it's just one IMAP connection anyway?
            let msgs = try await fetchMessagesIn(folder: uidsContext.path, uids: uidsContext.uids)
            for msg in msgs {
                messageContexts.append(MsgContext(path: uidsContext.path, msg: msg))
            }
        }

        // in case there are no messages return empty data
        // user will be prompted to create new backup
        guard messageContexts.isNotEmpty else {
            return Data()
        }

        let attachmentContexts = messageContexts.flatMap { msgContext -> [AttachmentContext] in
            guard let parts = msgContext.msg.attachments() as? [MCOIMAPPart] else { assertionFailure(); return [] }
            return parts.map { part in AttachmentContext(path: msgContext.path, msg: msgContext.msg, part: part) }
        }

        // in case there are no attachments return empty data
        guard attachmentContexts.isNotEmpty else {
            return Data()
        }

        var dataArr: [Data] = []
        for attachmentContext in attachmentContexts {
            let data = try await fetchMsgAttachment(
                in: attachmentContext.path,
                msgUid: attachmentContext.msg.uid,
                part: attachmentContext.part
            )
            dataArr.append(data + [10]) // newline
        }
        return dataArr.joined
    }

    // todo - this is likely a duplicate of another method on Imap class
    private func fetchMsgAttachment(in folder: String, msgUid: UInt32, part: MCOIMAPPart) async throws -> Data {
        try await execute("fetchMsgAttachment") { sess, respond in
            sess.fetchMessageAttachmentOperation(
                withFolder: folder,
                uid: msgUid,
                partID: part.partID,
                encoding: part.encoding
            ).start { error, value in respond(error, value) }
        }
    }

    private func subjectsExpr() throws -> MCOIMAPSearchExpression {
        let expressions = GeneralConstants.EmailConstant
            .recoverAccountSearchSubject
            .compactMap { MCOIMAPSearchExpression.searchSubject($0) }
        guard let expression = helper.createSearchExpressions(from: expressions) else {
            throw ImapError.createSearchExpression
        }
        return expression
    }

    private func createSearchBackupExpression(for email: String) throws -> MCOIMAPSearchExpression {
        let fromToExpr = MCOIMAPSearchExpression.searchAnd(
            MCOIMAPSearchExpression.search(from: email),
            other: MCOIMAPSearchExpression.search(to: email)
        )
        return MCOIMAPSearchExpression.searchAnd(fromToExpr, other: try subjectsExpr())
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

private struct AttachmentContext {
    let path: String
    let msg: MCOIMAPMessage
    let part: MCOIMAPPart
}
