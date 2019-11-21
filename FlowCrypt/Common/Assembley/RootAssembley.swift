//
//  RootAssembley.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/27/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import RealmSwift
import UIKit

protocol AppAssembley {
    func assemble()
    func setupWindow() -> UIWindow
    func startFlow() -> Bool
}

struct RootAssembley: AppAssembley {
    private let userService: UserServiceType
    private let assemblies: [Assembley]
    private let core: Core
    init(
        userService: UserServiceType = UserService.shared,
        assemblies: [Assembley] = AssembleyFactory.assemblies(),
        core: Core = Core.shared
    ) {
        self.userService = userService
        self.assemblies = assemblies
        self.core = core
    }

    func assemble() {
        DispatchQueue.promises = .global() // this helps prevent Promise deadlocks

        core.startInBackgroundIfNotAlreadyRunning()
    }

    func setupWindow() -> UIWindow {
        let window = UIWindow(frame: UIScreen.main.bounds) 

        guard userService.isSessionValid() else {
            let root = SignInViewController()
            window.rootViewController = MainNavigationController(rootViewController: root)
            window.makeKeyAndVisible()
            return window
        }

        // TODO: - Refactor with realm service
        let realm = try! Realm()
        let keys = realm.objects(KeyInfo.self)

        window.rootViewController = {
            if keys.count > 0 {
                return SideMenuNavigationController()
            } else {
                let root = SetupViewController()
                return MainNavigationController(rootViewController: root)
            }
        }()
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
