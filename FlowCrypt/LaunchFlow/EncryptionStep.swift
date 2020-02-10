//
//  EncryptionStep.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 10/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct EncryptionCheckLaunchStep: FlowStepHandler {
    let dataManager = DataManager.shared

    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool {
        guard dataManager.isSessionValid else {
            return copmlete(with: completion)
        }

        guard dataManager.isEncrypted else {
            fatalError("Storage is not encrypted")
            return fail(with: completion)
        }

        return copmlete(with: completion)
    }
}
