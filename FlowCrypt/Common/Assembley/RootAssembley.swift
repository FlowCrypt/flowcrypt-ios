//
//  RootAssembley.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/27/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import RealmSwift

protocol AppAssembley {
    func assemble()
    func setupWindow() -> UIWindow
    func startFlow() -> Bool
}

struct RootAssembley: AppAssembley {
    private let userService: UserServiceType
    private let assemblies: [Assembley]

    init(
        userService: UserServiceType = UserService.shared,
        assemblies: [Assembley] = AssembleyFactory.assemblies()
    ) {
        self.userService = userService
        self.assemblies = assemblies
    }

    func assemble() {
        DispatchQueue.promises = .global() // this helps prevent Promise deadlocks

        Core.startInBackgroundIfNotAlreadyRunning()
    }

    func setupWindow() -> UIWindow {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let storyboard = UIStoryboard.main

        guard var nv = storyboard.instantiateViewController(withIdentifier: "MainNavigationController") as? UINavigationController
            else { assert(); return UIWindow() }

        guard userService.isSessionValid() else {
            window.rootViewController = nv
            window.makeKeyAndVisible()
            return window
        }

        // TODO: - Refactor with realm service
        let realm = try! Realm()
        let keys = realm.objects(KeyInfo.self)

        if keys.count > 0 {
            let menu = storyboard.instantiate(SideMenuNavigationController.self)
            let inbox = InboxViewController()
            nv = menu
            nv.viewControllers = [inbox]
        } else {
            let vc = storyboard.instantiate(RecoverViewController.self)
            nv.viewControllers = [vc]
        }

        window.rootViewController = nv
        window.makeKeyAndVisible()

        return window
    }

    private func assert() {
        assertionFailure("Couldn't instantiate main controller")
    }

    func startFlow() -> Bool {
        assemblies.forEach { $0.assemble() }
        return true
    }
}

struct AssembleyFactory {
    private init() {}
    
    static func assemblies() -> [Assembley] {
        return [AuthAssembley()]
    }
}

protocol Assembley {
    func assemble()
}
