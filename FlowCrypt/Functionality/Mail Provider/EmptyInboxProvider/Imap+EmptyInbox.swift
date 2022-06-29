//
//  Imap+EmptyInbox.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 6/28/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import MailCore

extension Imap: EmptyInboxProvider {
    func emptyFolder(path: String) async throws {
//        let context = FetchMessageContext(folderPath: path, count: nil, pagination: .byNumber(total: 1000))
//        let list = try await fetchMessages(using: context)
//        let messageIdentifiers = list.messages.compactMap(\.identifier.intId)
        try await batchDeleteMessages(identifiers: [], from: path)
    }
}
