//
//  FlowController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol FlowController: FlowStepHandler { }

final class DefaultFlowController: FlowController {
    private let flow: [LaunchStepType]
    private let factory: LaunchFlowStepFactory

    private var launchContext: LaunchContext?
    private var currentStepHandler: FlowStepHandler?

    private var completion: ((Bool) -> Void)?

    init(flow: [LaunchStepType], factory: LaunchFlowStepFactory) {
        self.flow = flow
        self.factory = factory
    }

    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool {
//        assert(self.completion == nil && self.launchContext == nil)
        self.launchContext = launchContext
        self.completion = completion
        startExecutingFlow()
        return true
    }

    private func startExecutingFlow() {
        executeFlowStep(0)
    }

    private func executeFlowStep(_ index: Int) {
        guard index < flow.count else {
            complete(true)
            return
        }

        let step = flow[index]
        print("^^ \(#function)step\(step)")
        if let handler = factory.createLaunchStepHandler(for: step) {
            currentStepHandler = handler
            let executionStarted = executeFlowStep(for: handler, with: index)
            assert(executionStarted, "Execution of flow step \(index) could not be started")
        } else {
            executeFlowStep(index + 1)
        }
    }

    private func executeFlowStep(for handler: FlowStepHandler, with index: Int) -> Bool {
        guard let launchContext = launchContext else {
            assertionFailure("No context provided")
            return false
        }

        return handler.execute(with: launchContext) { continueFlow in
            if continueFlow {
                DispatchQueue.main.async {
                    self.executeFlowStep(index + 1)
                }
            } else {
                assertionFailure("Unexpected flow step failure \(handler)")
                self.complete(false)
            }
        }
    }

    private func complete(_ finished: Bool) {
        let completion = self.completion
        self.completion = nil
        completion?(finished)
    }
}
