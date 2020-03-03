//
//  User+Google.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import GoogleSignIn

extension User {
    init(_ googleUser: GIDGoogleUser!) {
        email = googleUser.profile.email
        name = googleUser.profile.name
    }
}
