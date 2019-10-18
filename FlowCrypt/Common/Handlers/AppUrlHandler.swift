//
//  AppUrlHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/27/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import GoogleSignIn

struct AppUrlHandler {
    private let googleApi: GIDSignIn

    init(googleApi: GIDSignIn = GIDSignIn.sharedInstance()) {
        self.googleApi = googleApi
    }

    func handle(_: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {

        return googleApi.handle(url)
    }
}
