//
//  UserCredentials.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 08/01/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct UserCredentials: Codable, Equatable {
    let email: String
    var password: String
    let pass: String
    let recovery: String
    let privateKey: String

    static var empty = UserCredentials(email: "", password: "", pass: "", recovery: "", privateKey: "")

    /// ci.tests.gmail@flowcrypt.dev
    /// default Gmail account
    static var gmailDev: UserCredentials = .user(with: "ci.tests.gmail@flowcrypt.dev")

    /// default@flowcrypt.test
    /// default IMAP/SMTP account
    static let imapDev = UserCredentials.user(with: "default@flowcrypt.test")

    /// den@flowcrypt.test
    /// user without messages
    static let imapDen = UserCredentials.user(with: "den@flowcrypt.test")

    /// has_msgs_no_backups@flowcrypt.test
    /// user with messages but without any backups
    static let imapHasMessagesNoBackups = UserCredentials.user(with: "has_msgs_no_backups@flowcrypt.test")

    /// denbond7@flowcrypt
    static let imapDenBond = UserCredentials.user(with: "denbond7@flowcrypt.test")
}

extension UserCredentials {
    static func user(with email: String) -> UserCredentials {
        Credentials.default
            .users
            .first(where: { $0.email == email })!
    }
}

struct Credentials: Codable {
    let users: [UserCredentials]

    static var `default`: Credentials = {
        guard let path = Bundle(for: SignInGoogleTest.self).path(forResource: "test-ci-secrets", ofType: "json") else {
            assertionFailure("No credentials found")
            return Credentials(users: [])
        }

        do {
            return try Data(contentsOf: URL(fileURLWithPath: path))
                .decodeJson(as: Credentials.self)
        } catch {
            assertionFailure("Wrong format for credentials\(error)")
            return Credentials(users: [])
        }
    }()
}
