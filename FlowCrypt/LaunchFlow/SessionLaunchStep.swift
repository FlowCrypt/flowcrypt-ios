//
//  BootstrapLaunchStep.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit

struct SessionLaunchStep: FlowStepHandler {
    let dataManager: DataManagerType = DataManager.shared
    let imap = Imap.shared

    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool {
        if dataManager.isSessionValid {
            imap.setup()

            launchContext.window.rootViewController = BootstrapViewController()

            imap.renewSession()
                .then(on: .main) {
                    completion(true)
                }.catch { _ in
                    completion(false)
                }
        } else {
            let root = SignInViewController()
            launchContext.window.rootViewController = MainNavigationController(rootViewController: root)
            completion(true)
        }

        launchContext.window.makeKeyAndVisible()
        return true
    }
}
