//
//  Trace.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 02.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import CoreFoundation
import Foundation

public final class Trace {
    private let id: String
    private var startTime: CFAbsoluteTime?

    public init(id: String) {
        self.id = id
        self.startTime = CFAbsoluteTimeGetCurrent()
    }

    public func result() -> TimeInterval {
        guard let startTime = startTime else {
            return 0
        }
        let endTime = CFAbsoluteTimeGetCurrent()

        return (endTime - startTime)
    }

    public func finish(roundedTo: Int = 3) -> String {
        let resultValue = result()

        let timeValue: String = resultValue <= 1 ? " ms" : " sec"

        return resultValue.roundedString(toPlace: roundedTo) + timeValue
    }
}
