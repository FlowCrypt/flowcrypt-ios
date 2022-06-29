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
        try await batchDeleteMessages(identifiers: [], from: path)
    }
}
