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
    let userService: GoogleUserService

    private var signInService: GIDSignIn {
        GIDSignIn.sharedInstance()
    }

    var gmailService: GTLRService {
        let service = GTLRGmailService()
        service.authorizer = userService.authorization
        return service
    }

    init(userService: GoogleUserService = GoogleUserService()) {
        self.userService = userService
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
