//
//  Imap+Helpers.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/12/2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol ImapHelperType {
    func createSet(
        for numberOfMessages: Int,
        total: Int,
        from: Int
    ) -> MCOIndexSet

    func createSearchExpressions(
        from possibleExpressions: [MCOIMAPSearchExpression]
    ) -> MCOIMAPSearchExpression?
}

struct ImapHelper: ImapHelperType {
    func createSet(
        for numberOfMessages: Int,
        total: Int,
        from: Int
    ) -> MCOIndexSet {
        var length = numberOfMessages - 1
        if length < 0 {
            length = 0
        }
        var diff = total - length - from
        if diff < 0 {
            diff = 1
        }
        let range = MCORange(location: UInt64(diff), length: UInt64(length))
        return MCOIndexSet(range: range)
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
