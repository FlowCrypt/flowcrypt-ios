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
}

struct ImapHelper: ImapHelperType {
    typealias ImapIndexSet = MCOIndexSet
    
    func createSet(
        for numberOfMessages: Int,
        total: Int,
        from: Int
    ) -> ImapIndexSet {
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
}

