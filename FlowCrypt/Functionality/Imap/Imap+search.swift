//
//  Imap+Search.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 19/12/2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

enum SearchDestinations: CaseIterable {
    case subject, from, to, recipient, content, body

    var searchExpresion: (String) -> (MCOIMAPSearchExpression) {
        { expression in
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

protocol SearchResultsProvider {
    func search(
        expression: String,
        in folder: String,
        destinaions: [SearchDestinations],
        count: Int,
        from: Int?
    ) -> Promise<[MCOIMAPMessage]>
}

extension Imap: SearchResultsProvider {
    func search(
        expression: String,
        in folder: String,
        destinaions: [SearchDestinations] = SearchDestinations.allCases,
        count _: Int,
        from _: Int?
    ) -> Promise<[MCOIMAPMessage]> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            let searchExpressions = self.helper.createSearchExpressions(
                from: destinaions.map { $0.searchExpresion(expression) }
            )

            guard let expression = searchExpressions else {
                return resolve([])
            }

            let kind = self.messageKindProvider.imapMessagesRequestKind
            let indexes = try await(self.fetchUids(folder: folder, expr: expression))

            let messages = try await(self.fetchMessagesByUIDOperation(
                for: folder,
                kind: kind,
                set: indexes
            )
            )
            return resolve(messages)
        }
    }

    func fetchUids(folder: String, expr: MCOIMAPSearchExpression) -> Promise<MCOIndexSet> {
        Promise<MCOIndexSet> { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            self.getImapSess()
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
