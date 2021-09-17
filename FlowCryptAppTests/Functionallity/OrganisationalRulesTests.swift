//
//  OrganisationalRulesTests.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 17.09.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
import XCTest
@testable import FlowCrypt

class OrganisationalRulesTests: XCTestCase {
    var sut: OrganisationalRules! {
        .init(clientConfiguration: clientConfiguration)
    }
    var clientConfiguration: ClientConfiguration!

    func testIsUsingKeyManagerURL() {
        clientConfiguration = ClientConfiguration(keyManagerUrl: "https://test.ekm.flowcrypt.com")
        XCTAssertTrue(sut.isUsingKeyManager)

        clientConfiguration = ClientConfiguration(keyManagerUrl: nil)
        XCTAssertFalse(sut.isKeyManagerUrlValid)
    }

    func testIsUsingValidKeyManagerURL() {
        // valid url check in
        clientConfiguration = ClientConfiguration(keyManagerUrl: "")
        XCTAssertFalse(sut.isKeyManagerUrlValid)

        clientConfiguration = ClientConfiguration(keyManagerUrl: "not a url string")
        XCTAssertFalse(sut.isKeyManagerUrlValid)
    }

    func testMustAutoImportOrAutogenPrvWithKeyManager() {
        clientConfiguration = ClientConfiguration(
            flags: [.privateKeyAutoimportOrAutogen],
            keyManagerUrl: "https://test.ekm.flowcrypt.com"
        )
        XCTAssertTrue(sut.mustAutoImportOrAutogenPrvWithKeyManager)

        clientConfiguration = ClientConfiguration(
            flags: [],
            keyManagerUrl: "https://test.ekm.flowcrypt.com"
        )
        XCTAssertFalse(sut.mustAutoImportOrAutogenPrvWithKeyManager)

        clientConfiguration = ClientConfiguration(
            flags: nil,
            keyManagerUrl: "https://test.ekm.flowcrypt.com"
        )
        XCTAssertFalse(sut.mustAutoImportOrAutogenPrvWithKeyManager)

        clientConfiguration = ClientConfiguration(
            flags: [.defaultRememberPassphrase, .hideArmorMeta, .enforceAttesterSubmit],
            keyManagerUrl: "https://test.ekm.flowcrypt.com"
        )
        XCTAssertFalse(sut.mustAutoImportOrAutogenPrvWithKeyManager)
    }

    func testMustAutogenPassPhraseQuietly() {
        clientConfiguration = ClientConfiguration(
            flags: [.passphraseQuietAutogen]
        )
        XCTAssertTrue(sut.mustAutogenPassPhraseQuietly)

        clientConfiguration = ClientConfiguration(flags: [])
        XCTAssertFalse(sut.mustAutogenPassPhraseQuietly)

        clientConfiguration = ClientConfiguration(flags: [.privateKeyAutoimportOrAutogen])
        XCTAssertFalse(sut.mustAutogenPassPhraseQuietly)

        clientConfiguration = ClientConfiguration(flags: nil)
        XCTAssertFalse(sut.mustAutogenPassPhraseQuietly)
    }

    func testForbidStoringPassPhrase() {
        clientConfiguration = ClientConfiguration(
            flags: [.forbidStoringPassphrase]
        )
        XCTAssertTrue(sut.forbidStoringPassPhrase)

        clientConfiguration = ClientConfiguration(flags: [])
        XCTAssertFalse(sut.forbidStoringPassPhrase)

        clientConfiguration = ClientConfiguration(flags: [.hideArmorMeta])
        XCTAssertFalse(sut.forbidStoringPassPhrase)

        clientConfiguration = ClientConfiguration(flags: nil)
        XCTAssertFalse(sut.forbidStoringPassPhrase)
    }

    func testMustSubmitAttester() {
        clientConfiguration = ClientConfiguration(
            flags: [.enforceAttesterSubmit]
        )
        XCTAssertTrue(sut.mustSubmitAttester)

        clientConfiguration = ClientConfiguration(flags: [])
        XCTAssertFalse(sut.mustSubmitAttester)

        clientConfiguration = ClientConfiguration(flags: [.hideArmorMeta])
        XCTAssertFalse(sut.mustSubmitAttester)

        clientConfiguration = ClientConfiguration(flags: nil)
        XCTAssertFalse(sut.mustSubmitAttester)
    }
}
