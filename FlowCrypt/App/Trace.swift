//
//  Trace.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 02.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
import CoreFoundation

final class Trace {
    private let id: String
    private var startTime: CFAbsoluteTime?

    init(id: String) {
        self.id = id
    }

    func start() -> Self {
        startTime = CFAbsoluteTimeGetCurrent()
        return self
    }

    func finish() -> TimeInterval {
        guard let startTime = startTime else {
            return 0
        }
        let endTime = CFAbsoluteTimeGetCurrent()

        return endTime - startTime
    }
}

