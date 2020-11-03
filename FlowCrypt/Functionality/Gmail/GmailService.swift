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

struct GmailService {
    let signInService: GIDSignIn
    let gmailService: GTLRService

    init(signInService: GIDSignIn, gmailService: GTLRService) {
        self.signInService = signInService
        self.gmailService = gmailService
        self.gmailService.authorizer = signInService.currentUser.authentication.fetcherAuthorizer()
    }
}

// TODO: - ANTON - Check. Maybe better to use class for GmailService (weak self)
