//
//  AuthLaunchStep.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import GoogleSignIn

struct AuthLaunchStep: FlowStepHandler {
    private weak var userService = UserService.shared

    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool {
        logDebug(100, "GoogleApi.setup()")

        guard let googleSignIn = GIDSignIn.sharedInstance() else {
            assertionFailure("Unexpected nil google instance")
            return false
        }

        googleSignIn.clientID = "679326713487-8f07eqt1hvjvopgcjeie4dbtni4ig0rc.apps.googleusercontent.com"
        googleSignIn.scopes = [
            "https://www.googleapis.com/auth/userinfo.profile",
            "https://mail.google.com/",
        ]

        googleSignIn.delegate = userService
        return copmlete(with: completion)
    }
}
