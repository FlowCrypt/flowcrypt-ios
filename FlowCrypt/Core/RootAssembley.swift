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

    private let googleApi: GoogleApi

    init(googleApi: GoogleApi = .shared) {
        self.googleApi = googleApi
    }

    func assemble() {
        DispatchQueue.promises = .global() // this helps prevent Promise deadlocks

        Core.startInBackgroundIfNotAlreadyRunning()

        googleApi.setup()
    }

    func setup(window: UIWindow?) {
        let storyboard = UIStoryboard.main

        guard var nv = storyboard.instantiateViewController(withIdentifier: "MainNavigationController") as? UINavigationController
            else { assert(); return }

        guard isValidSession() else {
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

    private func isValidSession() -> Bool {
        return googleApi.isGoogleSessionValid()
    }

    func startFlow() -> Bool {
        return true
    }
}
