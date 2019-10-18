//
//  UITestHelper.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import XCTest

final class UITestHelper {
    static func wait(for time: TimeInterval) {
        _ = XCTWaiter().wait(for: [XCTestExpectation(description: "dummy-expectation")], timeout: time)
    }

    static func wait(for element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)

        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    static func waitForAny(of elements: [XCUIElement], timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate { (object, _) -> Bool in
            guard let elements = object as? [XCUIElement] else { return false }
            return elements.reduce(false) { $0 || $1.exists }
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: elements)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
