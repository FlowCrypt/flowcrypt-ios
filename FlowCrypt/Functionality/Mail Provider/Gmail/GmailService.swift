//
//  GmailService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import GoogleAPIClientForREST_Gmail

class GmailService: MailServiceProvider {

    let currentUserEmail: String
    let mailServiceProviderType = MailServiceProviderType.gmail
    let googleAuthManager: GoogleAuthManagerType

    let logger = Logger.nested("GmailService")
    var gmailService: GTLRService {
        let service = GTLRGmailService()

        if Bundle.shouldUseMockGmailApi {
            service.rootURLString = GeneralConstants.Mock.backendUrl + "/"
        }

        service.uploadProgressBlock = { [weak self] _, uploaded, total in
            guard total > 0 else { return }
            let progress = Float(uploaded) / Float(total)
            self?.progressHandler?(progress)
        }

        guard let authorization = try? googleAuthManager.authorization(for: currentUserEmail) else {
            logger.logWarning("authorization for current user is nil")
            return service
        }

        service.authorizer = authorization
        return service
    }

    var progressHandler: ((Float) -> Void)?

    init(
        currentUserEmail: String,
        googleAuthManager: GoogleAuthManagerType
    ) {
        self.currentUserEmail = currentUserEmail
        self.googleAuthManager = googleAuthManager
    }
}

// Gmail string extension identifier
extension String {
    static let me = "me"
    static let from = "from"
    static let subject = "subject"
    static let date = "date"
    static let to = "to"
    static let cc = "cc"
    static let bcc = "bcc"
    static let replyTo = "reply-to"
    static let inReplyTo = "in-reply-to"
    static let receivedSPF = "received-spf"
    static let identifier = "message-id"
}
