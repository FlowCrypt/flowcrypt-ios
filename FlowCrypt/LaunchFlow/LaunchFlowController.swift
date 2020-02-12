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

    @discardableResult
    func startFlow(with launchContext: LaunchContext) -> Bool {
        let start = DispatchTime.now()
        return flowController.execute(with: launchContext) { completion in
            log("LaunchFlow execution finished", error: nil, res: completion, start: start)
        }
    }
}
