//
//  GmailSearchExpressionGenerator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

protocol GmailBackupSearchQueryProviderType {
    func makeBackupQuery(for email: String) throws -> String
}

final class GmailBackupSearchQueryProvider: GmailBackupSearchQueryProviderType {
    let core: Core

    init(core: Core = .shared) {
        self.core = core
    }

    func makeBackupQuery(for email: String) throws -> String {
        try core.gmailBackupSearch(for: email)
    }
}
