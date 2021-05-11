//
//  ExtensionTests.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
import XCTest

class ExtensionTests: XCTestCase {}

// MARK: - UIEdgeInsets

extension ExtensionTests {
    func test_side_inset() {
        let sut = UIEdgeInsets.side(16)

        XCTAssert(sut.left == 16)
        XCTAssert(sut.right == 16)
        XCTAssert(sut.top == 16)
        XCTAssert(sut.bottom == 16)
    }

    func test_width() {
        let sut = UIEdgeInsets.side(8)

        XCTAssert(sut.width == 16)
    }
}

// MARK: - Collection

extension ExtensionTests {
    func test_is_not_empty() {
        let someEmptyCollection: [String] = []
        let nonEmptyCollection = [1, 2, 3]

        XCTAssert(someEmptyCollection.isEmpty)
        XCTAssert(!nonEmptyCollection.isEmpty)
    }

    func test_safe_subscript() {
        let emptyCollection: [String] = []
        let nonEmptyCollection = [1, 2, 3]

        XCTAssertNil(emptyCollection[safe: 1])
        XCTAssertNotNil(nonEmptyCollection[safe: 1])
        XCTAssertNil(emptyCollection[safe: 5])
    }

    func test_mutable_collection_subsctipt() {
        var collection: [String]?

        collection?[safe: 0] = "zero"
        collection?[safe: 1] = "one"

        XCTAssertNil(collection?[safe: 0])
        XCTAssertNil(collection?[safe: 1])

        collection = ["zero"]

        XCTAssertNotNil(collection?[safe: 0])
    }
}
