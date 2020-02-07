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
    func createFlowStep(for step: LaunchStepType) -> FlowStepHandler? {
        switch step {
        case .bootstrap: return BootstrapFlowStep()
        case .mainSetup: return MainFlowStep()
        }
    }
}

// Example
struct BootstrapFlowStep: FlowStepHandler {
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


struct MainFlowStep: FlowStepHandler {
    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool {
        let vc = UIViewController()
        vc.view.backgroundColor = .blue
        launchContext.window.rootViewController = vc
        launchContext.window.makeKeyAndVisible()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            completion(true)
        }

        return true
    }
}

