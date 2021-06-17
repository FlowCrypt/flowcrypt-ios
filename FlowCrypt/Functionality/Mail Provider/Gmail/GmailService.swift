//
//  GmailService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST

struct GmailService: MailServiceProvider {
    let mailServiceProviderType = MailServiceProviderType.gmail
    let userService: GoogleUserService
    let backupGenerator: GmailSearchBackupGenerator

    let logger = Logger.nested("GmailService")
    var gmailService: GTLRService {
        let service = GTLRGmailService()

        if userService.authorization == nil {
            logger.logWarning("authorization for current user is nil")
        }

        service.authorizer = userService.authorization
        return service
    }

    init(
        userService: GoogleUserService = GoogleUserService(),
        backupGenerator: GmailSearchBackupGenerator = GmailSearchExpressionGenerator()
    ) {
        self.userService = userService
        self.backupGenerator = backupGenerator
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
