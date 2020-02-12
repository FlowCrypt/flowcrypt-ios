//
//  MainLaunchStep.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit

struct MainLaunchStep: FlowStepHandler {
    private let dataManager = DataManager.shared

    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool {
        guard dataManager.isSessionValid else {
            return copmlete(with: completion)
        }
 
        launchContext.window.rootViewController = dataManager.isLoggedIn
            ? SideMenuNavigationController()
            : MainNavigationController(rootViewController: SetupViewController())

        launchContext.window.makeKeyAndVisible()

        completion(true)
        return true
    }
}
