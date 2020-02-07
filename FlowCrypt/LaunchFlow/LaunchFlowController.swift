//
//  LaunchFlowController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct LaunchFlowController {
    static var `default`: LaunchFlowController = LaunchFlowController(
        flowController: DefaultFlowController(
            flow: LaunchFlow.default.steps,
            factory: LaunchFlowStepFactory()
        )
    )

    let flowController: FlowController

    init(flowController: FlowController) {
        self.flowController = flowController
    }

    func startFlow(with launchContext: LaunchContext) -> Bool {
        return flowController.execute { completion in
            print("^^ \(#function)\n\(completion)")
        }
    }
}
