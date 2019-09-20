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
    func searchBackups(email: String) -> Promise<Data>
}

extension Imap: BackupProvider {
    func searchBackups(email: String) -> Promise<Data> {
        return Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(FCError.general) }

            guard let backupSearchExpr = self.createSearchBackubExpression() else {
                return reject(FCError.general)
            }

            let folderContext = try await(self.fetchFolders())
            let folderPathes = folderContext.folders.compactMap { $0.path }
                .compactMap { (path: String) -> String? in
                    let gmailPath = Constants.Global.gmailPath
                    if path.isEmpty || path == gmailPath {
                        return nil
                    } else {
                        return path
                    }

                }

            // search uid and related folders
            typealias SearchContext = (set: MCOIndexSet, folder: String)
            let searchContext = try folderPathes
                .compactMap { folder -> SearchContext in
                    return (try await(self.fetchUID(folder: folder, expression: backupSearchExpr)), folder)
                }
                .filter { $0.set.count() > 0 }

            // array of message and related folder
            typealias MessageContext = (set: MCOIMAPMessage, folder: String)
            let messagesContext: [MessageContext] = try searchContext
                .compactMap {
                    try (await(self.fetchMessagesIn(folder: $0.1, uids: $0.0)), $0.1)
                }
                .compactMap { messages, folder in
                    messages.compactMap {
                        return ($0, folder)
                    }
                }
                .flatMap { $0 }


            typealias AttachmentsContext = (attachment: [MCOIMAPPart], message: MCOIMAPMessage, folder: String)
            typealias AttachmentContext = (attachment: MCOIMAPPart, message: MCOIMAPMessage, folder: String)
            let attachmentContext = messagesContext
                .compactMap { context -> AttachmentsContext? in
                    guard let attachments = context.0.attachments() as? [MCOIMAPPart] else { assertionFailure();
                        return nil
                    }

                    return (attachments, context.0, context.1)
                }
                .compactMap { context -> [AttachmentContext] in
                    context.attachment.compactMap {
                        return ($0, context.message, context.folder)
                    }
                }
                .flatMap { $0 }

            var data = Data()

            try attachmentContext.forEach { context in
                data += try await(self.fetchMsgAttribute(in: context.folder, msgUid: context.message.uid, part: context.attachment))
                data += [10] // newline
            }

            return resolve(data)
        }
    }

    private func fetchMsgAttribute(in folder: String, msgUid: UInt32, part: MCOIMAPPart) -> Promise<Data> {
        return Promise<Data> { [weak self] resolve, reject in
            guard let self = self else { return reject(FCError.general) }
            self.getImapSess()?
                .fetchMessageAttachmentOperation(withFolder: folder, uid: msgUid, partID: part.partID, encoding: part.encoding)
                .start(self.finalize("fetchMsgAtt", resolve, reject, retry: {
                    self.fetchMsgAttribute(in: folder, msgUid: msgUid, part: part)
                }))
            }
    }

    private func fetchMessagesIn(folder: String, uids: MCOIndexSet) -> Promise<[MCOIMAPMessage]> {
        return Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(FCError.general) }

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

    private func fetchMessage(in folder: String, kind: MCOIMAPMessagesRequestKind, uids: MCOIndexSet) -> Promise<[MCOIMAPMessage]> {
        return Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(FCError.general) }

            self.getImapSess()?
                .fetchMessagesOperation(withFolder: folder, requestKind: kind, uids: uids)?
                .start { (error, msgs, _) in
                    guard self.retryAuthErrorNotNeeded("fetchMsgs", error, resolve, reject, retry: {
                        self.fetchMessage(in: folder, kind: kind, uids: uids)
                    }) else { return }

                    if let messages = msgs as? [MCOIMAPMessage] {
                        return resolve(messages)
                    } else {
                        reject(FCError.message("fetchMsgs messages == nil"))
                    }
                }
        }
    }

    private func fetchUID(folder: String, expression: MCOIMAPSearchExpression) -> Promise<MCOIndexSet> {
        return Promise<MCOIndexSet> { resolve, reject in
            self.getImapSess()?
                .searchExpressionOperation(withFolder: folder, expression: expression)
                .start(self.finalize("searchExpression", resolve, reject, retry: { self.fetchUID(folder: folder, expression: expression)
                }))
        }
    }

    private func createSearchExpression(from expressions: [String]) -> MCOIMAPSearchExpression? {
        let array = expressions.compactMap { MCOIMAPSearchExpression.searchSubject($0) }
        guard array.count > 0 else { return nil }

        var resultArray: [MCOIMAPSearchExpression] = array
        while resultArray.count != 1 {
            let array = resultArray
                .chunked(2)
                .compactMap { (chunk) -> MCOIMAPSearchExpression? in
                    if let firstSearchExp = chunk.first {
                        if let secondSearchExp = chunk[safe: 1] {
                            return MCOIMAPSearchExpression.searchOr(firstSearchExp, other: secondSearchExp)
                        } else {
                            return firstSearchExp
                        }
                    } else {
                        return nil
                    }
                }
            resultArray = array
        }

        return resultArray.first
    }

    private func createSearchBackubExpression() -> MCOIMAPSearchExpression? {
        guard let searchExpression = createSearchExpression(from: Constants.EmailConstant.recoverAccountSearchSubject) else {
            return nil
        }

        let expression = MCOIMAPSearchExpression.searchOr(
            MCOIMAPSearchExpression.search(from: email),
            other: MCOIMAPSearchExpression.search(to: email)
        )

        guard let backupSearchExpr = MCOIMAPSearchExpression.searchAnd(expression, other: searchExpression) else {
            return searchExpression
        }

        return backupSearchExpr
    }
}
