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
    let password: String
    let pass: String
    let recovery: String
    let privateKey: String

    static var empty = UserCredentials(email: "", password: "", pass: "", recovery: "", privateKey: "")

    /// ci.tests.gmail@flowcrypt.dev
    static var gmailDev: UserCredentials = .user(with: "ci.tests.gmail@flowcrypt.dev")
    
    /// default@flowcrypt.test
    static var imapDev: UserCredentials = .user(with: "default@flowcrypt.test")
    
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
