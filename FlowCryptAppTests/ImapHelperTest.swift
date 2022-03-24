//
//  ImapHelperTest.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 23/12/2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import MailCore
import XCTest

class ImapHelperTest: XCTestCase {
    var sut: ImapHelperType!

    override func setUp() {
        sut = ImapHelper()
    }

    func test_create_set() {
        let set = sut.createSet(for: 12, total: 100, from: 0)
        let count = set.count()
        let indexSet = set.nsIndexSet()

        XCTAssert(count == 12)
        XCTAssert(indexSet?.count == 12)
        XCTAssert(indexSet?.last == 100)
        XCTAssert(indexSet?.first == 89)

        let countExpectation = XCTestExpectation()
        countExpectation.expectedFulfillmentCount = 12

        for _ in indexSet ?? [] {
            countExpectation.fulfill()
        }

        XCTAssert(IndexSet(integersIn: 89 ... 100) == indexSet)
    }

    func test_create_empty_set() {
        let set = sut.createSet(for: 0, total: 0, from: 0)
        XCTAssert(set.count() == 1)
        XCTAssert(set.nsIndexSet() == IndexSet(integer: 0))
    }

    func test_create_with_one() {
        let set = sut.createSet(for: 1, total: 83, from: 0)
        XCTAssert(set.count() == 1)
        XCTAssert(set.nsIndexSet() == IndexSet(integer: 83))
    }

    func test_create_search_expressions() {
        let emptyExpressions = sut.createSearchExpressions(from: [])
        XCTAssertNil(emptyExpressions)

        let possibleExpressionsOne = [MCOIMAPSearchExpression.search(from: "Ilon")!]

        let one = sut.createSearchExpressions(from: possibleExpressionsOne)
        XCTAssertNotNil(one)

        let possibleExpressions = [
            MCOIMAPSearchExpression.search(from: "Ilon")!,
            MCOIMAPSearchExpression.search(from: "Tesla")!,
            MCOIMAPSearchExpression.search(from: "Model S")!,
        ]

        let three = sut.createSearchExpressions(from: possibleExpressions)
        XCTAssertNotNil(three)
    }
}
