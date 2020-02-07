//
//  FlowStep.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol FlowStepHandler: Executable {
    func execute(_ completion: @escaping (Bool) -> Void) -> Bool
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
    func execute(_ completion: @escaping (Bool) -> Void) -> Bool {
        completion(true)
        return true
    }
}


struct MainFlowStep: FlowStepHandler {
    func execute(_ completion: @escaping (Bool) -> Void) -> Bool {
        completion(false)
        return true
    }
}

