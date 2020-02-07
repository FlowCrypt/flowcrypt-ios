//
//  MainLaunchStep.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct MainLaunchStep: FlowStepHandler {
    private let userService = UserService.shared
    private let dataManager = DataManager.shared

    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool {


        guard userService.isSessionValid else {
            let root = SignInViewController()
            launchContext.window.rootViewController = MainNavigationController(rootViewController: root)
            launchContext.window.makeKeyAndVisible()
            return true
        }

        launchContext.window.rootViewController = {
            if dataManager.isLogedIn {
                let vc = BootstrapViewController()
                vc.completion = { error in
                    launchContext.window.rootViewController = SideMenuNavigationController()
                }
                return vc
            } else {
                return MainNavigationController(rootViewController: SetupViewController())
            }
        }()
        launchContext.window.makeKeyAndVisible()




        //
        //
        //
        //        let vc = UIViewController()
        //        vc.view.backgroundColor = .blue
        //        launchContext.window.rootViewController = vc
        //        launchContext.window.makeKeyAndVisible()
        //
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        completion(true)
        //        }

        return true
    }
}
