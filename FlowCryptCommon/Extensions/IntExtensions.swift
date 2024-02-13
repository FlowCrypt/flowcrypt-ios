//
//  IntExtensions.swift
//  FlowCrypt
//
//  Created by luke on 8/1/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

public extension Int {
    func toDate() -> Date {
        Date(timeIntervalSince1970: TimeInterval(self))
    }
}

public extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    func roundedString(toPlace: Int) -> String {
        String(format: "%.\(toPlace)f", self)
    }
}
