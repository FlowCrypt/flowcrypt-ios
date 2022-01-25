//
//  ExtensionTests.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
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

    func test_mutable_collection_subscript() {
        var collection: [String]?

        collection?[safe: 0] = "zero"
        collection?[safe: 1] = "one"

        XCTAssertNil(collection?[safe: 0])
        XCTAssertNil(collection?[safe: 1])

        collection = ["zero"]

        XCTAssertNotNil(collection?[safe: 0])
    }

    func test_unique() {
        let collection = [1, 2, 2, 3, 4, 4]
        let uniqueCollection = collection.unique()

        XCTAssertEqual(uniqueCollection, [1, 2, 3, 4])
        XCTAssertEqual(uniqueCollection.unique(), uniqueCollection)
    }
}

// MARK: - Calendar
extension ExtensionTests {
    func test_calendar_date_formatting() throws {
        // 18:34
        let sameDayDate = Date()
        let dateFormatter = DateFormatter()

        let today = Date()
        let sameYearDate = try XCTUnwrap(
            Calendar.current.date(byAdding: .day, value: 1, to: today, wrappingComponents: true)
        )

        dateFormatter.dateFormat = "HH:mm"
        XCTAssertEqual(DateFormatter().formatDate(sameDayDate), dateFormatter.string(from: sameDayDate))

        dateFormatter.dateFormat = "MMM dd"
        XCTAssertEqual(DateFormatter().formatDate(sameYearDate), dateFormatter.string(from: sameYearDate))

        // Jan 24, 2020
        let otherYearDate = Date(timeIntervalSince1970: 1579883652)
        XCTAssertEqual(DateFormatter().formatDate(otherYearDate), "Jan 24, 2020")
    }
}
