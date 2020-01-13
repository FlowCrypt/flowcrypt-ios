//
//  UserCredentials.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 08/01/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct UserCredentials: Decodable {
    let email: String
    let password: String
    let pass: String
    let recovery: String
     
    static private var empty = UserCredentials(email: "", password: "", pass: "", recovery: "")
    
    static var `default`: UserCredentials = {
        guard let path = Bundle(for: SignInViewControllerTest.self).path(forResource: "test-ci-secrets", ofType: "json") else {
            assertionFailure("No credentials found")
            return .empty
        }
        
        do {
            return try Data(contentsOf: URL(fileURLWithPath: path))
                .decodeJson(as: UserCredentials.self)
        } catch {
            assertionFailure("Wrong format for credentials")
            return .empty
        }
    }()
}

