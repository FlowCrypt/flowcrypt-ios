//
//  CoreLaunchStep.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct CoreLaunchStep: FlowStepHandler {
    private let core: Core = Core.shared

    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool {
        // this helps prevent Promise deadlocks
        DispatchQueue.promises = .global()
        core.startInBackgroundIfNotAlreadyRunning()

        return copmlete(with: completion)
    }
}


