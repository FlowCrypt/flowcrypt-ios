//
//  LaunchStepType.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

// Holds all steps which will be executed during the launch of application
enum LaunchStepType: CaseIterable {
    case bootstrap
    case mainSetup
}

final class LaunchFlow {
    private(set) var steps: [LaunchStepType]

    init(steps: [LaunchStepType] = LaunchStepType.allCases) {
        self.steps = steps
    }

    func except(after stepA: LaunchStepType, do stepB: LaunchStepType) -> LaunchFlow {
        if let i = steps.firstIndex(of: stepA) {
            steps.insert(stepB, at: i + 1)
        }
        return self
    }
}


