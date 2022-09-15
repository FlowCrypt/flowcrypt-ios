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
    let gmailUserService: GoogleUserServiceType
    let backupSearchQueryProvider: GmailBackupSearchQueryProviderType

    let logger = Logger.nested("GmailService")
    var gmailService: GTLRService {
        let service = GTLRGmailService()

        if Bundle.shouldUseMockGmailApi {
            service.rootURLString = GeneralConstants.Mock.backendUrl + "/"
        }

        if gmailUserService.authorization == nil {
            logger.logWarning("authorization for current user is nil")
        }

        service.uploadProgressBlock = { [weak self] _, uploaded, total in
            guard total > 0 else { return }
            let progress = Float(uploaded) / Float(total)
            self?.progressHandler?(progress)
        }
        service.authorizer = gmailUserService.authorization
        return service
    }

    var progressHandler: ((Float) -> Void)?

    init(
        currentUserEmail: String,
        gmailUserService: GoogleUserServiceType,
        backupSearchQueryProvider: GmailBackupSearchQueryProviderType = GmailBackupSearchQueryProvider()
    ) {
        self.gmailUserService = gmailUserService
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
    static let to = "to"
    static let cc = "cc"
    static let bcc = "bcc"
    static let replyTo = "reply-to"
    static let inReplyTo = "in-reply-to"
    static let identifier = "message-id"
}
