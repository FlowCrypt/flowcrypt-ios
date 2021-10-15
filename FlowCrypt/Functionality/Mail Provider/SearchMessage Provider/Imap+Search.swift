//
//  Imap+Search.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import MailCore
import Promises

// MARK: - MessageSearchProvider
extension Imap: MessageSearchProvider {
    func searchExpression(using searchContext: MessageSearchContext) -> Promise<[Message]> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            let possibleExpressions = searchContext.searchDestinations.map {
                $0.searchExpresion(searchContext.expression)
            }
            let searchExpressions = self.helper.createSearchExpressions(
                from: possibleExpressions
            )
            guard let expression = searchExpressions else {
                return resolve([])
            }

            let kind = self.messageKindProvider.imapMessagesRequestKind
            let path = searchContext.folderPath ?? "INBOX"
            let indexes = try awaitPromise(self.fetchUids(folder: path, expr: expression))

            let messages = try awaitPromise(
                self.fetchMessagesByUIDOperation(
                    for: path,
                    kind: kind,
                    set: indexes
                )
            )
            .map(Message.init)

            resolve(messages)
        }
    }
}

extension Imap {
    func fetchUids(folder: String, expr: MCOIMAPSearchExpression) -> Promise<MCOIndexSet> {
        Promise<MCOIndexSet> { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            self.imapSess?
                .searchExpressionOperation(withFolder: folder, expression: expr)
                .start(self.finalize(
                    "searchExpression", resolve, reject,
                    retry: {
                        self.fetchUids(folder: folder, expr: expr)
                    }
                )
                )
        }
    }
}

// MARK: - Convenience
extension MessageSearchDestinations {
    var searchExpresion: (String) -> (MCOIMAPSearchExpression) {
        return { expression in
            switch self {
            case .subject: return MCOIMAPSearchExpression.searchSubject(expression)
            case .from: return MCOIMAPSearchExpression.search(from: expression)
            case .to: return MCOIMAPSearchExpression.search(to: expression)
            case .recipient: return MCOIMAPSearchExpression.searchRecipient(expression)
            case .content: return MCOIMAPSearchExpression.searchContent(expression)
            case .body: return MCOIMAPSearchExpression.searchBody(expression)
            }
        }
    }
}
