//
//  RootAssembley.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/27/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

#warning("Anton Remove")
protocol AppAssembley {
    func assemble()
    func setupWindow() -> UIWindow
    func startFlow() -> Bool
}

struct RootAssembley: AppAssembley {
    private let userService: UserServiceType
    private let assemblies: [Assembley]
    private let core: Core
    private let dataManager: DataManagerType

    init(
        userService: UserServiceType = UserService.shared,
        assemblies: [Assembley] = AssembleyFactory.assemblies(),
        core: Core = Core.shared,
        dataManager: DataManagerType = DataManager.shared
    ) {
        self.userService = userService
        self.assemblies = assemblies
        self.core = core
        self.dataManager = dataManager
    }

    func assemble() {
        DispatchQueue.promises = .global() // this helps prevent Promise deadlocks

        core.startInBackgroundIfNotAlreadyRunning()
    }

    func setupWindow() -> UIWindow {
        let window = UIWindow(frame: UIScreen.main.bounds) 

//        guard userService.isSessionValid() else {
//            let root = SignInViewController()
//            window.rootViewController = MainNavigationController(rootViewController: root)
//            window.makeKeyAndVisible()
//            return window
//        }
// 
//        window.rootViewController = {
//            if dataManager.isLogedIn {
//                let vc = BootstrapViewController()
//                vc.completion = { error in
//                    window.rootViewController = SideMenuNavigationController()
//                }
//                return vc
//            } else {
//                return MainNavigationController(rootViewController: SetupViewController())
//            }
//        }()
//        window.makeKeyAndVisible()

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

