//
//  BootstrapLaunchStep.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit

struct SessionLaunchStep: FlowStepHandler {
    let userService: UserServiceType = UserService.shared

    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool {
        guard userService.isSessionValid else { return copmlete(with: completion) }

        let vc = BootstrapViewController()
        launchContext.window.rootViewController = vc

        vc.completion = { error in
            launchContext.window.rootViewController = SideMenuNavigationController()
        }


//        launchContext.isUserLogedIn = userService.isLogedIn

        let vc = UIViewController()
        vc.view.backgroundColor = .red
        launchContext.window.rootViewController = vc
        launchContext.window.makeKeyAndVisible()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(true)
        }
        return true
    }
}
