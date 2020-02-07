//
//  FlowStep.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol FlowStepHandler {
    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool
}

// For every launch step creates Handler which will handle the executable step
struct LaunchFlowStepFactory {
    func createLaunchStepHandler(for step: LaunchStepType) -> FlowStepHandler? {
        switch step {
        case .core:
            return CoreLaunchStep()
        case .authentication:
            return AuthLaunchStep()
        case .dataBase:
            return nil
        case .session:
            return BootstrapLaunchStep()
        case .main:
            return MainLaunchStep()
        }
    }
}


struct CoreLaunchStep: FlowStepHandler {
    private let core: Core = Core.shared
    
    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool {
        DispatchQueue.promises = .global() // this helps prevent Promise deadlocks
        core.startInBackgroundIfNotAlreadyRunning()
        completion(true)
        return true
    }
}



import GoogleSignIn
struct AuthLaunchStep: FlowStepHandler {
    private weak var userService = UserService.shared

    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool {
        logDebug(100, "GoogleApi.setup()")

        guard let googleSignIn = GIDSignIn.sharedInstance() else {
            assertionFailure("Unexpected nil google instance")
            return true
        }

        googleSignIn.clientID = "679326713487-8f07eqt1hvjvopgcjeie4dbtni4ig0rc.apps.googleusercontent.com"
        googleSignIn.scopes = [
            "https://www.googleapis.com/auth/userinfo.profile",
            "https://mail.google.com/",
        ]

        googleSignIn.delegate = userService
        completion(true)
        return true
    }
}







struct BootstrapLaunchStep: FlowStepHandler {
    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool {
        let vc = UIViewController()
        vc.view.backgroundColor = .red
        launchContext.window.rootViewController = vc
        launchContext.window.makeKeyAndVisible()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            completion(true)
        }
        return true
    }
}


struct MainLaunchStep: FlowStepHandler {
    private let userService = UserService.shared
    private let dataManager = DataManager.shared

    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool {


        guard userService.isSessionValid() else {
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

