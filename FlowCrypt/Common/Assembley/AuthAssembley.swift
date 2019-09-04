//
//  AuthAssembley.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/29/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import GoogleSignIn

struct AuthAssembley: Assembley {
    private let service = UserService.shared

    func assemble() {
        GIDSignIn.sharedInstance().clientID = "679326713487-8f07eqt1hvjvopgcjeie4dbtni4ig0rc.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().scopes = [
            "https://www.googleapis.com/auth/userinfo.profile",
            "https://mail.google.com/"
        ]
        service.setup()
    }
}
