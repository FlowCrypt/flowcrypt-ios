//
//  Imap+Search.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import MailCore

// MARK: - MessageSearchApiClient
extension Imap: MessageSearchApiClient {
    func searchExpression(using searchContext: MessageSearchContext) async throws -> [Message] {
        let possibleExpressions = searchContext.searchDestinations.map {
            $0.searchExpression(searchContext.expression)
        }
        let searchExpressions = helper.createSearchExpressions(
            from: possibleExpressions
        )
        guard let expression = searchExpressions else {
            return []
        }
        let kind = messageKindProvider.imapMessagesRequestKind
        let path = searchContext.folderPath ?? "INBOX"
        let indexes = try await fetchUids(folder: path, expr: expression)
        return try await fetchMessagesByUIDOperation(for: path, kind: kind, set: indexes).map(Message.init)
    }
}

extension Imap {
    func fetchUids(folder: String, expr: MCOIMAPSearchExpression) async throws -> MCOIndexSet {
        return try await execute("searchExpression") { sess, respond in
            sess.searchExpressionOperation(
                withFolder: folder,
                expression: expr
            ).start { error, value in respond(error, value) }
        }
    }
}

// MARK: - Convenience
extension MessageSearchDestinations {
    var searchExpression: (String) -> (MCOIMAPSearchExpression) {
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
