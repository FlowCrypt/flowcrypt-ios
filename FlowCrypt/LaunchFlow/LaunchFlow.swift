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
    /// Setup Core of the project
    case core
    /// Setup database, encrypt and perform migration if needed
    case dataBase
    /// Setup services required for user notification
    case authentication
    /// Setup a session. Create or renewe Imap session
    case session
    /// Check if user have encrypted realm storage
    case encryption
    /// Presenting flow for user
    case main
}

final class LaunchFlow {
    static var `default`: LaunchFlow = LaunchFlow(steps: LaunchStepType.allCases)

    private(set) var steps: [LaunchStepType]

    private init(steps: [LaunchStepType]) {
        self.steps = steps
    }

    // will be used to handle different app launches, like open from push notification or deeplink
    func except(after stepA: LaunchStepType, do stepB: LaunchStepType) -> LaunchFlow {
        if let i = steps.firstIndex(of: stepA) {
            steps.insert(stepB, at: i + 1)
        }
        return self
    }
}


