//
//  GmailService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

struct GmailService: MailServiceProvider {
    let mailServiceProviderType = MailServiceProviderType.gmail

    private var signInService: GIDSignIn {
        GIDSignIn.sharedInstance()
    }

    var gmailService: GTLRService {
        let service = GTLRGmailService()
        service.authorizer = signInService.currentUser.authentication.fetcherAuthorizer()
        return service
    }

    let userService: GoogleUserService = .shared
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
