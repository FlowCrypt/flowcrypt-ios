//
//  Gmail+EmptyInbox.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 6/28/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import GoogleAPIClientForREST_Gmail

extension GmailService: EmptyInboxProvider {
    func emptyFolder(path: String) async throws {
        let context = FetchMessageContext(folderPath: path, count: nil, pagination: nil)
        let list = try await fetchMessagesList(using: context)
        let messageIdentifiers = list.messages?.compactMap(\.identifier) ?? []
        try await batchDeleteMessages(identifiers: messageIdentifiers, from: path)
    }
}
