//
//  IntExtension.swift
//  FlowCrypt
//
//  Created by luke on 8/1/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

public extension Int {
    func toDate() -> Date {
        Date(timeIntervalSince1970: TimeInterval(self))
    }
}
