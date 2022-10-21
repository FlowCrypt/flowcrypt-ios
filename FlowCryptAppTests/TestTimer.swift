//
//  TestTimer.swift
//  FlowCryptCommon
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import CoreFoundation

class TestTimer {

    private var startTime: CFAbsoluteTime?
    private var endTime: CFAbsoluteTime?

    func start() {
        startTime = CFAbsoluteTimeGetCurrent()
    }

    func stop() {
        endTime = CFAbsoluteTimeGetCurrent()
    }

    var durationMs: Double {
        if let startTime, let endTime {
            return (endTime - startTime) * 1000
        }
        return 0
    }
}
