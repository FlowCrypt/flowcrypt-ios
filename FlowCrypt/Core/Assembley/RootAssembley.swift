//
//  RootAssembley.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/27/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import GoogleSignIn
import RealmSwift
import IQKeyboardManagerSwift

protocol AppAssembley {
    func assemble()
    func setup(window: UIWindow?)
    func startFlow() -> Bool
}

struct RootAssembley: AppAssembley {
    private let userService: UserService
    private let assembleys: [Assembley]

    init(
        userService: UserService = .shared,
        assembleys: [Assembley] = AssembleyFactory.assembleys()
    ) {
        self.userService = userService
        self.assembleys = assembleys
    }

    func assemble() {
        DispatchQueue.promises = .global() // this helps prevent Promise deadlocks

        Core.startInBackgroundIfNotAlreadyRunning()
    }

    func setup(window: UIWindow?) {
        let storyboard = UIStoryboard.main

        guard var nv = storyboard.instantiateViewController(withIdentifier: "MainNavigationController") as? UINavigationController
            else { assert(); return }

        guard userService.isSessionValid() else {
            window?.rootViewController = nv
            window?.makeKeyAndVisible()
            return
        }

        // TODO: - Refactor with realm service
        let realm = try! Realm()
        let keys = realm.objects(KeyInfo.self)

        if keys.count > 0 {
            let menu = storyboard.instantiate(SideMenuNavigationController.self)
            let inbox = storyboard.instantiate(InboxViewController.self)
            nv = menu
            nv.viewControllers = [inbox]
        } else {
            let vc = storyboard.instantiate(RecoverViewController.self)
            nv.viewControllers = [vc]
        }

        window?.rootViewController = nv
        window?.makeKeyAndVisible()
    }

    private func assert() {
        assertionFailure("Couldn't instantiate main controller")
    }

    func startFlow() -> Bool {
        assembleys.forEach { $0.assemble() }
        return true
    }
}

struct AssembleyFactory {
    private init() {}
    
    static func assembleys() -> [Assembley] {
        return [AuthAssembley()]
    }
}

protocol Assembley {
    func assemble()
}

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
