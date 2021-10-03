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
    var sut: OrganisationalRules! {
        .init(clientConfiguration: clientConfiguration)
    }
    var clientConfiguration: ClientConfigurationWrapper!

    func testIsUsingKeyManagerURL() {
        clientConfiguration = ClientConfigurationWrapper(keyManagerUrl: "https://ekm.example.com")
        XCTAssertTrue(sut.isUsingKeyManager)

        clientConfiguration = ClientConfigurationWrapper(keyManagerUrl: nil)
        XCTAssertFalse(sut.isKeyManagerUrlValid)
    }

    func testIsUsingValidKeyManagerURL() {
        // valid url check in
        clientConfiguration = ClientConfigurationWrapper(keyManagerUrl: "")
        XCTAssertFalse(sut.isKeyManagerUrlValid)

        clientConfiguration = ClientConfigurationWrapper(keyManagerUrl: "not a url string")
        XCTAssertFalse(sut.isKeyManagerUrlValid)
    }

    func testMustAutoImportOrAutogenPrvWithKeyManager() {
        clientConfiguration = ClientConfigurationWrapper(
            flags: [.privateKeyAutoimportOrAutogen],
            keyManagerUrl: "https://ekm.example.com"
        )
        XCTAssertTrue(sut.mustAutoImportOrAutogenPrvWithKeyManager)

        clientConfiguration = ClientConfigurationWrapper(
            flags: [],
            keyManagerUrl: "https://ekm.example.com"
        )
        XCTAssertFalse(sut.mustAutoImportOrAutogenPrvWithKeyManager)

        clientConfiguration = ClientConfigurationWrapper(
            flags: nil,
            keyManagerUrl: "https://ekm.example.com"
        )
        XCTAssertFalse(sut.mustAutoImportOrAutogenPrvWithKeyManager)

        clientConfiguration = ClientConfigurationWrapper(
            flags: [.defaultRememberPassphrase, .hideArmorMeta, .enforceAttesterSubmit],
            keyManagerUrl: "https://ekm.example.com"
        )
        XCTAssertFalse(sut.mustAutoImportOrAutogenPrvWithKeyManager)
    }

    func testMustAutogenPassPhraseQuietly() {
        clientConfiguration = ClientConfigurationWrapper(
            flags: [.passphraseQuietAutogen]
        )
        XCTAssertTrue(sut.mustAutogenPassPhraseQuietly)

        clientConfiguration = ClientConfigurationWrapper(flags: [])
        XCTAssertFalse(sut.mustAutogenPassPhraseQuietly)

        clientConfiguration = ClientConfigurationWrapper(flags: [.privateKeyAutoimportOrAutogen])
        XCTAssertFalse(sut.mustAutogenPassPhraseQuietly)

        clientConfiguration = ClientConfigurationWrapper(flags: nil)
        XCTAssertFalse(sut.mustAutogenPassPhraseQuietly)
    }

    func testForbidStoringPassPhrase() {
        clientConfiguration = ClientConfigurationWrapper(
            flags: [.forbidStoringPassphrase]
        )
        XCTAssertTrue(sut.forbidStoringPassPhrase)

        clientConfiguration = ClientConfigurationWrapper(flags: [])
        XCTAssertFalse(sut.forbidStoringPassPhrase)

        clientConfiguration = ClientConfigurationWrapper(flags: [.hideArmorMeta])
        XCTAssertFalse(sut.forbidStoringPassPhrase)

        clientConfiguration = ClientConfigurationWrapper(flags: nil)
        XCTAssertFalse(sut.forbidStoringPassPhrase)
    }

    func testMustSubmitAttester() {
        clientConfiguration = ClientConfigurationWrapper(
            flags: [.enforceAttesterSubmit]
        )
        XCTAssertTrue(sut.mustSubmitAttester)

        clientConfiguration = ClientConfigurationWrapper(flags: [])
        XCTAssertFalse(sut.mustSubmitAttester)

        clientConfiguration = ClientConfigurationWrapper(flags: [.hideArmorMeta])
        XCTAssertFalse(sut.mustSubmitAttester)

        clientConfiguration = ClientConfigurationWrapper(flags: nil)
        XCTAssertFalse(sut.mustSubmitAttester)
    }
}
