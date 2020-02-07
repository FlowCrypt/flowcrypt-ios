//
//  LaunchFlowStep.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol FlowStepHandler {
    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool
}

extension FlowStepHandler {
    func copmlete(with completion: @escaping (Bool) -> Void) -> Bool {
        completion(true)
        return true
    }

    func fail(with completion: @escaping (Bool) -> Void) -> Bool {
        completion(false)
        return false
    }
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
            return DataBaseLaunchStep()
        case .session:
            return SessionLaunchStep()
        case .main:
            return MainLaunchStep()
        }
    }
}
