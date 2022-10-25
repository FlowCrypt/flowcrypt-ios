//
//  XCTestCaseExtension.swift
//  FlowCryptAppTests
//
//  Created by Roma Sosnovsky on 29/03/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import XCTest

extension XCTestCase {
    func assert<E: Error & Equatable>(
        _ expression: @autoclosure () throws -> some Any,
        throws error: E,
        in file: StaticString = #file,
        line: UInt = #line
    ) {
        var thrownError: Error?

        XCTAssertThrowsError(try expression(),
                             file: file, line: line) {
            thrownError = $0
        }

        XCTAssertTrue(
            thrownError is E,
            "Unexpected error type: \(type(of: thrownError))",
            file: file, line: line
        )

        XCTAssertEqual(
            thrownError as? E, error,
            file: file, line: line
        )
    }
}
