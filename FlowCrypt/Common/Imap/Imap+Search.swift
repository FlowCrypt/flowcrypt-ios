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
        return { expression in
            switch self {
            case .subject: return MCOIMAPSearchExpression.searchSubject(expression)
            case .from: return MCOIMAPSearchExpression.search(from: expression)
            case .to: return MCOIMAPSearchExpression.search(to:expression)
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
    ) -> Promise<MessageContext>
     
    func createSearchExpressions(from possibleExpressions: [MCOIMAPSearchExpression]) -> MCOIMAPSearchExpression?
}

extension Imap: SearchResultsProvider {
    func search(
        expression: String,
        in folder: String,
        destinaions: [SearchDestinations] = SearchDestinations.allCases,
        count: Int,
        from: Int?
    ) -> Promise<MessageContext> {
        return Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }
           
            let session = self.getImapSess()
            let searchExpressions = self.createSearchExpressions(
                from: destinaions.map { $0.searchExpresion(expression) }
            )
            let operation = session.searchExpressionOperation(
                withFolder: folder,
                expression: searchExpressions
            )
            operation?.start { (error, indexSet) in
                print(indexSet!)
            }
            
            
            return reject(AppErr.nilSelf)
        }
    }
     
    func createSearchExpressions(from possibleExpressions: [MCOIMAPSearchExpression]) -> MCOIMAPSearchExpression? {
        
        if possibleExpressions.isEmpty {
            return nil
        }
        
        if possibleExpressions.count == 1 {
            return possibleExpressions[0]
        }
        
        let possibleResult: [MCOIMAPSearchExpression] = possibleExpressions
            .chunked(2)
            .compactMap { chunk -> MCOIMAPSearchExpression? in
                guard let firstSearchExp = chunk.first else { return nil }
                guard let secondSearchExp = chunk[safe: 1] else { return firstSearchExp }
                return MCOIMAPSearchExpression.searchOr(
                    firstSearchExp,
                    other: secondSearchExp
                )
        }
        return createSearchExpressions(from: possibleResult)
    }
}
