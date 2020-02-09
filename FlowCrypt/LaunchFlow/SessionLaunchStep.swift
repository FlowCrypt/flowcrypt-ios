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
            
            // googleManager.restorePreviousSignIn() doesn't return error if session can't be restored.
            // should be reworked to have some failure callback and completion should be called after receiveing a new session
            // or after receiving error
            launchContext.window.rootViewController = BootstrapViewController()
            imap.renewSession()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                completion(true)
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
