//
//  Gmail+Search.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.12.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Promises
import GTMSessionFetcher
import GoogleAPIClientForREST

extension GmailService: MessageSearchProvider {
    func searchExpression(using context: MessageSearchContext) -> Promise<[Message]> {
        Promise { (resolve, _) in
            let context = try await(self.fetchMessages(using: FetchMessageContext(searchContext: context)))
            resolve(context.messages)
        }
    }
}

extension FetchMessageContext {
    init(searchContext: MessageSearchContext) {
        let folder = searchContext.folderPath ?? "anywhere"
        let query = "in:\(folder) \(searchContext.expression) OR subject:e\(searchContext.expression)"
        self.init(
            folderPath: searchContext.folderPath,
            count: searchContext.count,
            searchQuery: query,
            pagination: nil
        )
    }
}
