//
//  ClientConfigurationEvaluatorTest.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 10.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import XCTest
@testable import FlowCrypt

// check if Email Key Manager should be used test and other client configuration is consistent
class ClientConfigurationEvaluatorTest: XCTestCase {

    var sut: ClientConfigurationEvaluator!
    var clientConfigurationService = OrganisationalRulesServiceMock()

    override func setUp() {
        super.setUp()

        sut = ClientConfigurationEvaluator(clientConfigurationService: clientConfigurationService)
    }

    func testCheckDoesNotUseEKM() {
        // EKM should not be used if keyManagerUrl is nil
        clientConfigurationService.clientConfiguration = RawClientConfiguration(keyManagerUrl: nil)
        XCTAssert(sut.checkShouldUseEKM() == .doesNotUseEKM)

        // EKM should not be used if keyManagerUrl is nil
        clientConfigurationService.clientConfiguration = RawClientConfiguration(
            flags: [],
            keyManagerUrl: nil
        )
        XCTAssert(sut.checkShouldUseEKM() == .doesNotUseEKM)

        clientConfigurationService.clientConfiguration = RawClientConfiguration(
            flags: [.forbidStoringPassphrase],
            keyManagerUrl: nil
        )
        XCTAssert(sut.checkShouldUseEKM() == .doesNotUseEKM)
    }

    func testShouldUseEKM() {
        clientConfigurationService.clientConfiguration = RawClientConfiguration(
            flags: [
                .privateKeyAutoimportOrAutogen,
                .forbidStoringPassphrase
            ],
            keyManagerUrl: "https://ekm.example.com"
        )

        XCTAssert(sut.checkShouldUseEKM() == .usesEKM)
    }

    func testCheckShouldUseEKMShouldFailWithoutValidURL() {
        clientConfigurationService.clientConfiguration = RawClientConfiguration(
            flags: [
                .privateKeyAutoimportOrAutogen,
                .forbidStoringPassphrase
            ],
            keyManagerUrl: ""
        )

        let result = sut.checkShouldUseEKM()
        guard case .inconsistentClientConfiguration(let error) = result else {
            return XCTFail()
        }

        XCTAssert(error == .urlNotValid)
    }

    func testCheckShouldUseEKMFailForAutogen() {
        // No flags
        clientConfigurationService.clientConfiguration = RawClientConfiguration(
            flags: nil,
            keyManagerUrl: "https://ekm.example.com"
        )

        var result = sut.checkShouldUseEKM()
        guard case .inconsistentClientConfiguration(let error) = result else {
            return XCTFail()
        }

        XCTAssert(error == .autoImportOrAutogenPrvWithKeyManager)

        // Empty flags
        clientConfigurationService.clientConfiguration = RawClientConfiguration(
            flags: [],
            keyManagerUrl: "https://ekm.example.com"
        )

        result = sut.checkShouldUseEKM()
        guard case .inconsistentClientConfiguration(let emptyFlagsError) = result else {
            return XCTFail()
        }

        XCTAssert(emptyFlagsError == .autoImportOrAutogenPrvWithKeyManager)
    }

    func testCheckShouldUseEKMFailForAutoImportOrAutogen() {
        // Wrong flags (without privateKeyAutoimportOrAutogen flag)
        clientConfigurationService.clientConfiguration = RawClientConfiguration(
            flags: [
                .noAttesterSubmit
            ],
            keyManagerUrl: "https://ekm.example.com"
        )

        let result = sut.checkShouldUseEKM()
        guard case .inconsistentClientConfiguration(let wrongFlagError) = result else {
            return XCTFail()
        }

        XCTAssert(wrongFlagError == .autoImportOrAutogenPrvWithKeyManager)
    }

    func testCheckShouldUseEKMFailForAutogenPassPhraseQuietly() {
        // sut pass mustAutoImportOrAutogenPrvWithKeyManager check
        clientConfigurationService.clientConfiguration = RawClientConfiguration(
            flags: [
                .privateKeyAutoimportOrAutogen,
                .passphraseQuietAutogen
            ],
            keyManagerUrl: "https://ekm.example.com"
        )

        let result = sut.checkShouldUseEKM()
        guard case .inconsistentClientConfiguration(let error) = result else {
            return XCTFail()
        }

        XCTAssert(error == .autogenPassPhraseQuietly)
    }

    func testCheckShouldUseEKMFailForForbidStoringPassPhrase() {
        clientConfigurationService.clientConfiguration = RawClientConfiguration(
            flags: [
                .privateKeyAutoimportOrAutogen
            ],
            keyManagerUrl: "https://ekm.example.com"
        )

        let result = sut.checkShouldUseEKM()
        guard case .inconsistentClientConfiguration(let error) = result else {
            return XCTFail()
        }

        XCTAssert(error == .forbidStoringPassPhrase)
    }

    func testCheckShouldUseEKMFailForMustSubmitAttester() {
        clientConfigurationService.clientConfiguration = RawClientConfiguration(
            flags: [
                .privateKeyAutoimportOrAutogen,
                .forbidStoringPassphrase,
                .enforceAttesterSubmit
            ],
            keyManagerUrl: "https://ekm.example.com"
        )

        let result = sut.checkShouldUseEKM()
        guard case .inconsistentClientConfiguration(let error) = result else {
            return XCTFail()
        }

        XCTAssert(error == .mustSubmitAttester)
    }
}
