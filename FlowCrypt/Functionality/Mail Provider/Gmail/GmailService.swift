//
//  GmailService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation
import GoogleAPIClientForREST_Gmail

class GmailService: MailServiceProvider {
    let mailServiceProviderType = MailServiceProviderType.gmail
    let userService: GoogleUserServiceType
    let backupSearchQueryProvider: GmailBackupSearchQueryProviderType

    let logger = Logger.nested("GmailService")
    var gmailService: GTLRService {
        let service = GTLRGmailService()

        if userService.authorization == nil {
            logger.logWarning("authorization for current user is nil")
        }

        service.uploadProgressBlock = { [weak self] _, uploaded, total in
            guard total > 0 else { return }
            let progress = Float(uploaded) / Float(total)
            self?.progressHandler?(progress)
        }
        service.authorizer = userService.authorization
        return service
    }

    var progressHandler: ((Float) -> Void)?

    init(
        userService: GoogleUserServiceType = GoogleUserService(),
        backupSearchQueryProvider: GmailBackupSearchQueryProviderType = GmailBackupSearchQueryProvider()
    ) {
        self.userService = userService
        self.backupSearchQueryProvider = backupSearchQueryProvider
    }
}

// Gmail string extension identifier
extension String {
    static let me = "me"
}

extension String {
    static let from = "from"
    static let subject = "subject"
    static let date = "date"
    static let identifier = "Message-ID"
}
