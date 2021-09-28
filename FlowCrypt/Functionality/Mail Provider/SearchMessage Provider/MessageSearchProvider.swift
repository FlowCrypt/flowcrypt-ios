//
//  MessageSearchProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Promises

enum MessageSearchDestinations: CaseIterable {
    case subject, from, to, recipient, content, body
}

struct MessageSearchContext {
    let expression: String
    let folderPath: String?
    let searchDestinations: [MessageSearchDestinations]
    let count: Int?
    let from: Int

    init(
        expression: String,
        folderPath: String? = nil,
        searchDestinations: [MessageSearchDestinations] = MessageSearchDestinations.allCases,
        count: Int? = nil,
        from: Int = 0
    ) {
        self.expression = expression
        self.folderPath = folderPath
        self.searchDestinations = searchDestinations
        self.count = count
        self.from = from
    }
}

protocol MessageSearchProvider {
    func searchExpression(using context: MessageSearchContext) -> Promise<[Message]>
}
