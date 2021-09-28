//
//  PubLookupTests.swift
//  FlowCryptAppTests
//
//  Created by  Ivan Ushakov on 28.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import XCTest
import Promises
@testable import FlowCrypt

final class PubLookupTests: XCTestCase {

    private var promisesQueue: DispatchQueue!

    override func setUp() {
        super.setUp()
        promisesQueue = DispatchQueue.promises
        DispatchQueue.promises = .global()
    }

    override func tearDown() {
        DispatchQueue.promises = promisesQueue
        super.tearDown()
    }

    func testLookup() {
        // arrange
        let wkd = WKDURLsApiMock()
        wkd.result = [
            KeyDetails(
                public: "",
                private: nil,
                isFullyDecrypted: nil,
                isFullyEncrypted: nil,
                ids: [],
                created: 1,
                lastModified: 2,
                expiration: 3,
                users: [],
                algo: nil
            )
        ]
        let attesterApi = AttesterApiMock()
        let lookup = PubLookup(wkd: wkd, attesterApi: attesterApi)

        // act
        let expectation = XCTestExpectation()

        var result: Contact?
        lookup.lookup(with: "user@example.org").then(on: .main) {
            result = $0
            expectation.fulfill()
        }.catch(on: .main) { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5, enforceOrder: true)

        // assert
        XCTAssertEqual(result?.name, "user@example.org")
        XCTAssertEqual(result?.pubkeyCreated, Date(timeIntervalSince1970: TimeInterval(1)))
        XCTAssertEqual(result?.pubKeyLastSig, Date(timeIntervalSince1970: TimeInterval(2)))
        XCTAssertEqual(result?.pubkeyExpiresOn, Date(timeIntervalSince1970: TimeInterval(3)))
    }
}

private final class WKDURLsApiMock: WKDURLsApiType {

    var result: [KeyDetails] = []

    func lookupEmail(_ email: String) -> Promise<[KeyDetails]> {
        return Promise<[KeyDetails]>.resolveAfter(
            with: Result<[KeyDetails], Error>.success(result)
        )
    }
}

private final class AttesterApiMock: AttesterApiType {

    func lookupEmail(email: String) -> Promise<[KeyDetails]> {
        return Promise<[KeyDetails]>.resolveAfter(
            with: Result<[KeyDetails], Error>.success([])
        )
    }

    func updateKey(email: String, pubkey: String, token: String?) -> Promise<String> {
        return Promise<String>.resolveAfter(
            with: Result<String, Error>.failure(MockError.some)
        )
    }

    func replaceKey(email: String, pubkey: String) -> Promise<String> {
        return Promise<String>.resolveAfter(
            with: Result<String, Error>.failure(MockError.some)
        )
    }

    func testWelcome(email: String, pubkey: String) -> Promise<Void> {
        return Promise<Void>.resolveAfter(
            with: Result<Void, Error>.failure(MockError.some)
        )
    }
}
