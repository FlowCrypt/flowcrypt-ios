//
//  StringTestExtension.swift
//  FlowCryptAppTests
//
//  Created by Roma Sosnovsky on 28/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

extension String {
    static func random(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in letters.randomElement()! })
    }
}
