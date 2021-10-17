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

    func testCheckDoesNotUseEKM() {
        // EKM should not be used if keyManagerUrl is nil
        XCTAssert(ClientConfiguration(raw: RawClientConfiguration(keyManagerUrl: nil)).checkUsesEKM() == .doesNotUseEKM)

        // EKM should not be used if keyManagerUrl is nil
        XCTAssert(ClientConfiguration(raw: RawClientConfiguration(
            flags: [],
            keyManagerUrl: nil
        )).checkUsesEKM() == .doesNotUseEKM)


        XCTAssert(ClientConfiguration(raw: RawClientConfiguration(
            flags: [.forbidStoringPassphrase],
            keyManagerUrl: nil
        )).checkUsesEKM() == .doesNotUseEKM)
    }

    func testShouldUseEKM() {
        XCTAssert(ClientConfiguration(raw: RawClientConfiguration(
            flags: [
                .privateKeyAutoimportOrAutogen,
                .forbidStoringPassphrase
            ],
            keyManagerUrl: "https://ekm.example.com"
        )).checkUsesEKM() == .usesEKM)
    }

    func testCheckShouldUseEKMShouldFailWithoutValidURL() {
        let result = ClientConfiguration(raw: RawClientConfiguration(
            flags: [
                .privateKeyAutoimportOrAutogen,
                .forbidStoringPassphrase
            ],
            keyManagerUrl: ""
        )).checkUsesEKM()
        guard case .inconsistentClientConfiguration(let error) = result else {
            return XCTFail()
        }
        XCTAssert(error == .urlNotValid)
    }

    func testCheckShouldUseEKMFailForAutogen() {
        // No flags
        var result = ClientConfiguration(raw: RawClientConfiguration(
            flags: nil,
            keyManagerUrl: "https://ekm.example.com"
        )).checkUsesEKM()
        guard case .inconsistentClientConfiguration(let error) = result else {
            return XCTFail()
        }

        XCTAssert(error == .autoImportOrAutogenPrvWithKeyManager)

        // Empty flags
        result = ClientConfiguration(raw: RawClientConfiguration(
            flags: [],
            keyManagerUrl: "https://ekm.example.com"
        )).checkUsesEKM()
        guard case .inconsistentClientConfiguration(let emptyFlagsError) = result else {
            return XCTFail()
        }

        XCTAssert(emptyFlagsError == .autoImportOrAutogenPrvWithKeyManager)
    }

    func testCheckShouldUseEKMFailForAutoImportOrAutogen() {
        // Wrong flags (without privateKeyAutoimportOrAutogen flag)
        let result = ClientConfiguration(raw: RawClientConfiguration(
            flags: [
                .noAttesterSubmit
            ],
            keyManagerUrl: "https://ekm.example.com"
        )).checkUsesEKM()
        guard case .inconsistentClientConfiguration(let wrongFlagError) = result else {
            return XCTFail()
        }

        XCTAssert(wrongFlagError == .autoImportOrAutogenPrvWithKeyManager)
    }

    func testCheckShouldUseEKMFailForAutogenPassPhraseQuietly() {
        // sut pass mustAutoImportOrAutogenPrvWithKeyManager check
        let result = ClientConfiguration(raw: RawClientConfiguration(
            flags: [
                .privateKeyAutoimportOrAutogen,
                .passphraseQuietAutogen
            ],
            keyManagerUrl: "https://ekm.example.com"
        )).checkUsesEKM()
        guard case .inconsistentClientConfiguration(let error) = result else {
            return XCTFail()
        }

        XCTAssert(error == .autogenPassPhraseQuietly)
    }

    func testCheckShouldUseEKMFailForForbidStoringPassPhrase() {
        let result = ClientConfiguration(raw: RawClientConfiguration(
            flags: [
                .privateKeyAutoimportOrAutogen
            ],
            keyManagerUrl: "https://ekm.example.com"
        )).checkUsesEKM()
        guard case .inconsistentClientConfiguration(let error) = result else {
            return XCTFail()
        }

        XCTAssert(error == .forbidStoringPassPhrase)
    }

    func testCheckShouldUseEKMFailForMustSubmitAttester() {
        let result = ClientConfiguration(raw: RawClientConfiguration(
            flags: [
                .privateKeyAutoimportOrAutogen,
                .forbidStoringPassphrase,
                .enforceAttesterSubmit
            ],
            keyManagerUrl: "https://ekm.example.com"
        )).checkUsesEKM()
        guard case .inconsistentClientConfiguration(let error) = result else {
            return XCTFail()
        }

        XCTAssert(error == .mustSubmitAttester)
    }
}
