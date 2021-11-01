//
//  Gmail+Search.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import GoogleAPIClientForREST_Gmail

extension GmailService: MessageSearchProvider {
    func searchExpression(using context: MessageSearchContext) async throws -> [Message] {
        let context = try await self.fetchMessages(using: FetchMessageContext(searchContext: context))
        return context.messages
    }
}

extension FetchMessageContext {
    init(searchContext: MessageSearchContext) {
        let folder = searchContext.folderPath ?? "anywhere"
        let query = "in:\(folder) \(searchContext.expression) OR subject:\(searchContext.expression)"
        self.init(
            folderPath: searchContext.folderPath,
            count: searchContext.count,
            searchQuery: query,
            pagination: nil
        )
    }
}
