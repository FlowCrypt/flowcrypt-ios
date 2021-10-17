//
//  OrganisationalRulesTests.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 17.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import XCTest
@testable import FlowCrypt

class OrganisationalRulesTests: XCTestCase {
    var sut: ClientConfiguration! {
        .init(raw: clientConfiguration)
    }
    var clientConfiguration: RawClientConfiguration!

    func testIsUsingKeyManagerURL() {
        clientConfiguration = RawClientConfiguration(keyManagerUrl: "https://ekm.example.com")
        XCTAssertTrue(sut.isUsingKeyManager)

        clientConfiguration = RawClientConfiguration(keyManagerUrl: nil)
        XCTAssertFalse(sut.isKeyManagerUrlValid)
    }

    func testIsUsingValidKeyManagerURL() {
        // valid url check in
        clientConfiguration = RawClientConfiguration(keyManagerUrl: "")
        XCTAssertFalse(sut.isKeyManagerUrlValid)

        clientConfiguration = RawClientConfiguration(keyManagerUrl: "not a url string")
        XCTAssertFalse(sut.isKeyManagerUrlValid)
    }

    func testMustAutoImportOrAutogenPrvWithKeyManager() {
        clientConfiguration = RawClientConfiguration(
            flags: [.privateKeyAutoimportOrAutogen],
            keyManagerUrl: "https://ekm.example.com"
        )
        XCTAssertTrue(sut.mustAutoImportOrAutogenPrvWithKeyManager)

        clientConfiguration = RawClientConfiguration(
            flags: [],
            keyManagerUrl: "https://ekm.example.com"
        )
        XCTAssertFalse(sut.mustAutoImportOrAutogenPrvWithKeyManager)

        clientConfiguration = RawClientConfiguration(
            flags: nil,
            keyManagerUrl: "https://ekm.example.com"
        )
        XCTAssertFalse(sut.mustAutoImportOrAutogenPrvWithKeyManager)

        clientConfiguration = RawClientConfiguration(
            flags: [.defaultRememberPassphrase, .hideArmorMeta, .enforceAttesterSubmit],
            keyManagerUrl: "https://ekm.example.com"
        )
        XCTAssertFalse(sut.mustAutoImportOrAutogenPrvWithKeyManager)
    }

    func testMustAutogenPassPhraseQuietly() {
        clientConfiguration = RawClientConfiguration(
            flags: [.passphraseQuietAutogen]
        )
        XCTAssertTrue(sut.mustAutogenPassPhraseQuietly)

        clientConfiguration = RawClientConfiguration(flags: [])
        XCTAssertFalse(sut.mustAutogenPassPhraseQuietly)

        clientConfiguration = RawClientConfiguration(flags: [.privateKeyAutoimportOrAutogen])
        XCTAssertFalse(sut.mustAutogenPassPhraseQuietly)

        clientConfiguration = RawClientConfiguration(flags: nil)
        XCTAssertFalse(sut.mustAutogenPassPhraseQuietly)
    }

    func testForbidStoringPassPhrase() {
        clientConfiguration = RawClientConfiguration(
            flags: [.forbidStoringPassphrase]
        )
        XCTAssertTrue(sut.forbidStoringPassPhrase)

        clientConfiguration = RawClientConfiguration(flags: [])
        XCTAssertFalse(sut.forbidStoringPassPhrase)

        clientConfiguration = RawClientConfiguration(flags: [.hideArmorMeta])
        XCTAssertFalse(sut.forbidStoringPassPhrase)

        clientConfiguration = RawClientConfiguration(flags: nil)
        XCTAssertFalse(sut.forbidStoringPassPhrase)
    }

    func testMustSubmitAttester() {
        clientConfiguration = RawClientConfiguration(
            flags: [.enforceAttesterSubmit]
        )
        XCTAssertTrue(sut.mustSubmitAttester)

        clientConfiguration = RawClientConfiguration(flags: [])
        XCTAssertFalse(sut.mustSubmitAttester)

        clientConfiguration = RawClientConfiguration(flags: [.hideArmorMeta])
        XCTAssertFalse(sut.mustSubmitAttester)

        clientConfiguration = RawClientConfiguration(flags: nil)
        XCTAssertFalse(sut.mustSubmitAttester)
    }
}
