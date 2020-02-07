//
//  FlowController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol Executable {
    func execute(_ completion: @escaping (Bool) -> Void) -> Bool
}

protocol FlowController: Executable { }

final class DefaultFlowController: FlowController {
    private let flow: [LaunchStepType]
    private let factory: LaunchFlowStepFactory

    private var currentStepHandler: FlowStepHandler?

    private var completion: ((Bool) -> Void)?

    init(flow: [LaunchStepType], factory: LaunchFlowStepFactory) {
        self.flow = flow
        self.factory = factory
    }

    func execute(_ completion: @escaping (Bool) -> Void) -> Bool {
        assert(self.completion == nil)
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

        let stepType = flow[index]
        print("^^ \(#function) stepType=\(stepType)")

        if let handler = factory.createFlowStep(for: stepType) {
            currentStepHandler = handler
            let executionStarted = executeFlowStep(for: handler, with: index)
            assert(executionStarted, "Execution of flow step \(index) could not be started")
        } else {
            executeFlowStep(index + 1)
        }
    }

    private func executeFlowStep(for handler: FlowStepHandler, with index: Int) -> Bool {
        handler.execute { continueFlow in
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
