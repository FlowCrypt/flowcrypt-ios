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
    func createFlowStep(for type: LaunchStepType) -> FlowStepHandler? {
        return nil
    }
}

// Example
struct PushFlowStep: FlowStepHandler {
    func execute(_ completion: @escaping (Bool) -> Void) -> Bool {
        return true
    }
}


