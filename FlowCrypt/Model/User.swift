//
//  User.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import GoogleSignIn

struct User: Codable {
    let email: String
    let name: String
}

extension User {
    init(_ googleUser: GIDGoogleUser!) {
        email = googleUser.profile.email
        name = googleUser.profile.name
    }
}
