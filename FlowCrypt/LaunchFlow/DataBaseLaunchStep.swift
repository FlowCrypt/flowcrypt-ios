//
//  DataBaseLaunchStep.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct DataBaseLaunchStep: FlowStepHandler {
    let dataManager = DataManager.shared

    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool {
        guard dataManager.isLogedIn else { return copmlete(with: completion) }
        dataManager.performMigrationIfNeeded()
        return copmlete(with: completion)
    }
}
