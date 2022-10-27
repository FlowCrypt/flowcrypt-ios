//
//  OrganisationalRulesTests.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 17.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class ClientConfigurationTests: XCTestCase {

    func testIsUsingKeyManagerURL() {
        XCTAssertTrue(ClientConfiguration(raw: RawClientConfiguration(keyManagerUrl: "https://ekm.example.com")).isUsingKeyManager)

        XCTAssertFalse(ClientConfiguration(raw: RawClientConfiguration(keyManagerUrl: nil)).isKeyManagerUrlValid)
    }

    func testIsUsingValidKeyManagerURL() {
        // valid url check in
        XCTAssertFalse(ClientConfiguration(raw: RawClientConfiguration(keyManagerUrl: "")).isKeyManagerUrlValid)

        XCTAssertFalse(ClientConfiguration(raw: RawClientConfiguration(keyManagerUrl: "not a url string")).isKeyManagerUrlValid)
    }

    func testIsUsingFes() {
        XCTAssertTrue(ClientConfiguration(raw: RawClientConfiguration(fesUrl: "https://fes.flowcrypt.com")).isUsingFes)
    }

    func testMustAutoImportOrAutogenPrvWithKeyManager() {
        XCTAssertTrue(try ClientConfiguration(raw: RawClientConfiguration(
            flags: [.privateKeyAutoimportOrAutogen],
            keyManagerUrl: "https://ekm.example.com"
        )).mustAutoImportOrAutogenPrvWithKeyManager)

        XCTAssertFalse(try ClientConfiguration(raw: RawClientConfiguration(
            flags: [],
            keyManagerUrl: "https://ekm.example.com"
        )).mustAutoImportOrAutogenPrvWithKeyManager)

        XCTAssertFalse(try ClientConfiguration(raw: RawClientConfiguration(
            flags: nil,
            keyManagerUrl: "https://ekm.example.com"
        )).mustAutoImportOrAutogenPrvWithKeyManager)

        XCTAssertFalse(try ClientConfiguration(raw: RawClientConfiguration(
            flags: [.defaultRememberPassphrase, .hideArmorMeta, .enforceAttesterSubmit],
            keyManagerUrl: "https://ekm.example.com"
        )).mustAutoImportOrAutogenPrvWithKeyManager)
    }

    func testMustAutogenPassPhraseQuietly() {
        XCTAssertTrue(ClientConfiguration(raw: RawClientConfiguration(
            flags: [.passphraseQuietAutogen]
        )).mustAutogenPassPhraseQuietly)

        XCTAssertFalse(ClientConfiguration(raw: RawClientConfiguration(flags: [])).mustAutogenPassPhraseQuietly)

        XCTAssertFalse(ClientConfiguration(raw: RawClientConfiguration(flags: [.privateKeyAutoimportOrAutogen])).mustAutogenPassPhraseQuietly)

        XCTAssertFalse(ClientConfiguration(raw: RawClientConfiguration(flags: nil)).mustAutogenPassPhraseQuietly)
    }

    func testForbidStoringPassPhrase() {
        XCTAssertTrue(ClientConfiguration(raw: RawClientConfiguration(
            flags: [.forbidStoringPassphrase]
        )).forbidStoringPassPhrase)

        XCTAssertFalse(ClientConfiguration(raw: RawClientConfiguration(flags: [])).forbidStoringPassPhrase)

        XCTAssertFalse(ClientConfiguration(raw: RawClientConfiguration(flags: [.hideArmorMeta])).forbidStoringPassPhrase)

        XCTAssertFalse(ClientConfiguration(raw: RawClientConfiguration(flags: nil)).forbidStoringPassPhrase)
    }

    func testMustSubmitAttester() {
        XCTAssertTrue(ClientConfiguration(raw: RawClientConfiguration(
            flags: [.enforceAttesterSubmit]
        )).mustSubmitAttester)

        XCTAssertFalse(ClientConfiguration(raw: RawClientConfiguration(flags: [])).mustSubmitAttester)

        XCTAssertFalse(ClientConfiguration(raw: RawClientConfiguration(flags: [.hideArmorMeta])).mustSubmitAttester)

        XCTAssertFalse(ClientConfiguration(raw: RawClientConfiguration(flags: nil)).mustSubmitAttester)
    }

    func testHideArmorMeta() {
        XCTAssertTrue(ClientConfiguration(raw: RawClientConfiguration(
            flags: [.hideArmorMeta]
        )).shouldHideArmorMeta)

        XCTAssertFalse(ClientConfiguration(raw: RawClientConfiguration(flags: [])).shouldHideArmorMeta)
    }

    func testCheckDoesNotUseEKM() {
        // EKM should not be used if keyManagerUrl is nil
        XCTAssert(try ClientConfiguration(raw: RawClientConfiguration(keyManagerUrl: nil)).checkUsesEKM() == .doesNotUseEKM)

        // EKM should not be used if keyManagerUrl is nil
        XCTAssert(try ClientConfiguration(raw: RawClientConfiguration(
            flags: [],
            keyManagerUrl: nil
        )).checkUsesEKM() == .doesNotUseEKM)

        XCTAssert(try ClientConfiguration(raw: RawClientConfiguration(
            flags: [.forbidStoringPassphrase],
            keyManagerUrl: nil
        )).checkUsesEKM() == .doesNotUseEKM)
    }

    func testShouldUseEKM() {
        XCTAssert(try ClientConfiguration(raw: RawClientConfiguration(
            flags: [
                .privateKeyAutoimportOrAutogen,
                .forbidStoringPassphrase
            ],
            keyManagerUrl: "https://ekm.example.com"
        )).checkUsesEKM() == .usesEKM)
    }

    func testCheckShouldUseEKMShouldFailWithoutValidURL() throws {
        let result = try ClientConfiguration(raw: RawClientConfiguration(
            flags: [
                .privateKeyAutoimportOrAutogen,
                .forbidStoringPassphrase
            ],
            keyManagerUrl: ""
        )).checkUsesEKM()
        guard case let .inconsistentClientConfiguration(error) = result else {
            return XCTFail()
        }
        XCTAssert(error == .urlNotValid)
    }

    func testCheckShouldUseEKMFailForAutogen() throws {
        // No flags
        var result = try ClientConfiguration(raw: RawClientConfiguration(
            flags: nil,
            keyManagerUrl: "https://ekm.example.com"
        )).checkUsesEKM()
        guard case let .inconsistentClientConfiguration(error) = result else {
            return XCTFail()
        }

        XCTAssert(error == .autoImportOrAutogenPrvWithKeyManager)

        // Empty flags
        result = try ClientConfiguration(raw: RawClientConfiguration(
            flags: [],
            keyManagerUrl: "https://ekm.example.com"
        )).checkUsesEKM()
        guard case let .inconsistentClientConfiguration(emptyFlagsError) = result else {
            return XCTFail()
        }

        XCTAssert(emptyFlagsError == .autoImportOrAutogenPrvWithKeyManager)
    }

    func testCheckShouldUseEKMFailForAutoImportOrAutogen() throws {
        // Wrong flags (without privateKeyAutoimportOrAutogen flag)
        let result = try ClientConfiguration(raw: RawClientConfiguration(
            flags: [
                .noAttesterSubmit
            ],
            keyManagerUrl: "https://ekm.example.com"
        )).checkUsesEKM()
        guard case let .inconsistentClientConfiguration(wrongFlagError) = result else {
            return XCTFail()
        }

        XCTAssert(wrongFlagError == .autoImportOrAutogenPrvWithKeyManager)
    }

    func testCheckShouldUseEKMFailForAutogenPassPhraseQuietly() throws {
        // sut pass mustAutoImportOrAutogenPrvWithKeyManager check
        let result = try ClientConfiguration(raw: RawClientConfiguration(
            flags: [
                .privateKeyAutoimportOrAutogen,
                .passphraseQuietAutogen
            ],
            keyManagerUrl: "https://ekm.example.com"
        )).checkUsesEKM()
        guard case let .inconsistentClientConfiguration(error) = result else {
            return XCTFail()
        }

        XCTAssert(error == .autogenPassPhraseQuietly)
    }

    func testCheckShouldUseEKMFailForMustSubmitAttester() throws {
        let result = try ClientConfiguration(raw: RawClientConfiguration(
            flags: [
                .privateKeyAutoimportOrAutogen,
                .forbidStoringPassphrase,
                .enforceAttesterSubmit
            ],
            keyManagerUrl: "https://ekm.example.com"
        )).checkUsesEKM()
        guard case let .inconsistentClientConfiguration(error) = result else {
            return XCTFail()
        }

        XCTAssert(error == .mustSubmitAttester)
    }
}
