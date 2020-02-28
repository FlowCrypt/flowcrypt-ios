//
//  GoogleService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 28/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import GoogleSignIn

protocol GoogleServiceType {
    func setUpAuthentication() throws
}

final class GoogleService: GoogleServiceType {
    enum Scope: CaseIterable {
        case userInfo, mail, feed, contacts
        var value: String {
            switch self {
            case .userInfo: return "https://www.googleapis.com/auth/userinfo.profile"
            case .mail: return "https://mail.google.com/"
            case .feed: return "https://www.google.com/m8/feeds"
            case .contacts: return "https://www.googleapis.com/auth/contacts.readonly"
            }
        }
    }

    private var instance = GIDSignIn.sharedInstance()

    func setUpAuthentication() throws {
        guard let googleSignIn = instance else { throw AppErr.general("Unexpected nil GIDSignIn") }
        googleSignIn.clientID = "679326713487-8f07eqt1hvjvopgcjeie4dbtni4ig0rc.apps.googleusercontent.com"
        googleSignIn.scopes = Scope.allCases.compactMap { $0.value }
        googleSignIn.delegate = UserService.shared
    }
}
