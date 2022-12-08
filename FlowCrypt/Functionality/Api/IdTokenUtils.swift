//
//  IdTokenUtils.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 3/25/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

class IdTokenUtils {
    // Get id token from user or user email
    static func getIdToken(user: User? = nil, userEmail: String? = nil) async throws -> String {
        if let user, case .password = user.authType {
            return try Imap(user: user).imapSess.oAuth2Token
        }

        let googleService = GoogleAuthManager(
            currentUserEmail: userEmail ?? user?.email,
            appDelegateGoogleSessionContainer: nil
        )

        return try await googleService.getCachedOrRefreshedIdToken()
    }
}
