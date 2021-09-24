//
//  ClientConfigurationServiceTest.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 10.09.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import XCTest
@testable import FlowCrypt

// check if Email Key Manager should be used test and other client configuration is consistent
class ClientConfigurationServiceTest: XCTestCase {

    var sut: ClientConfigurationService!
    var organisationalRulesService = OrganisationalRulesServiceMock()

    override func setUp() {
        super.setUp()

        sut = ClientConfigurationService(organisationalRulesService: organisationalRulesService)
    }

    func testCheckDoesNotUseEKM() {
        // EKM should not be used if keyManagerUrl is nil
        organisationalRulesService.clientConfiguration = ClientConfiguration(keyManagerUrl: nil)
        XCTAssert(sut.checkShouldUseEKM() == .doesNotUseEKM)

        // EKM should not be used if keyManagerUrl is nil
        organisationalRulesService.clientConfiguration = ClientConfiguration(
            flags: [],
            keyManagerUrl: nil
        )
        XCTAssert(sut.checkShouldUseEKM() == .doesNotUseEKM)

        organisationalRulesService.clientConfiguration = ClientConfiguration(
            flags: [.forbidStoringPassphrase],
            keyManagerUrl: nil
        )
        XCTAssert(sut.checkShouldUseEKM() == .doesNotUseEKM)
    }

    func testShouldUseEKM() {
        organisationalRulesService.clientConfiguration = ClientConfiguration(
            flags: [
                .privateKeyAutoimportOrAutogen,
                .forbidStoringPassphrase
            ],
            keyManagerUrl: "https://ekm.example.com"
        )

        XCTAssert(sut.checkShouldUseEKM() == .usesEKM)
    }

    func testCheckShouldUseEKMShouldFailWithoutValidURL() {
        organisationalRulesService.clientConfiguration = ClientConfiguration(
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
        organisationalRulesService.clientConfiguration = ClientConfiguration(
            flags: nil,
            keyManagerUrl: "https://ekm.example.com"
        )

        var result = sut.checkShouldUseEKM()
        guard case .inconsistentClientConfiguration(let error) = result else {
            return XCTFail()
        }

        XCTAssert(error == .autoImportOrAutogenPrvWithKeyManager)

        // Empty flags
        organisationalRulesService.clientConfiguration = ClientConfiguration(
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
        organisationalRulesService.clientConfiguration = ClientConfiguration(
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
        organisationalRulesService.clientConfiguration = ClientConfiguration(
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
        organisationalRulesService.clientConfiguration = ClientConfiguration(
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
        organisationalRulesService.clientConfiguration = ClientConfiguration(
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
