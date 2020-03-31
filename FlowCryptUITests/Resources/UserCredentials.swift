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
    
    static var main: UserCredentials = {
        Credentials.default
            .users
            .first(where: { $0.email == "cryptup.tester@gmail.com" })!
    }()

    static var noKeyBackUp: UserCredentials = {
        Credentials.default
            .users
            .first(where: { $0.email == "flowcrypt.test.anton@gmail.com" })!
    }()

    static var yahoo: UserCredentials = {
        Credentials.default
            .users
            .first(where: { $0.email == "antonflowcrypt@yahoo.com" })!
    }()
}

struct Credentials: Codable {
    let users: [UserCredentials]

    static var `default`: Credentials = {
        guard let path = Bundle(for: SignInTest.self).path(forResource: "test-ci-secrets", ofType: "json") else {
            assertionFailure("No credentials found")
            return Credentials(users: [])
        }

        do {
            return try Data(contentsOf: URL(fileURLWithPath: path))
                .decodeJson(as: Credentials.self)
        } catch let error {
            assertionFailure("Wrong format for credentials\(error)")
            return Credentials(users: [])
        }
    }()
}
