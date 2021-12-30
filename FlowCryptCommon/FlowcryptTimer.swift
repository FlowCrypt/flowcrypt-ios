//
//  FlowcryptTimer.swift
//  FlowCryptCommon
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import CoreFoundation

class FlowcryptTimer {

    private var startTime: CFAbsoluteTime?
    private var endTime: CFAbsoluteTime?

    func start() {
        startTime = CFAbsoluteTimeGetCurrent()
    }

    func stop() {
        endTime = CFAbsoluteTimeGetCurrent()
    }

    var duration: CFAbsoluteTime {
        if let startTime = startTime, let endTime = endTime {
            return endTime - startTime
        }
        return 0
    }
}
