//
//  KeyServiceTests.swift
//  FlowCryptAppTests
//
//  Created by  Ivan Ushakov on 15.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

final class KeyServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()

        let expectation = XCTestExpectation()
        Task {
            await Core.shared.startIfNotAlreadyRunning()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func testGetSigningKeyFirstEmail() async throws {
        // arrange
        let userObject = UserRealmObject(name: "Bill", email: "bill@example.test", imap: nil, smtp: nil)

        guard let key1 = try await Core.shared.parseKeys(armoredOrBinary: Self.privateKey1.data()).keyDetails.first else {
            XCTFail("key details expected")
            return
        }
        guard let key2 = try await Core.shared.parseKeys(armoredOrBinary: Self.privateKey2.data()).keyDetails.first else {
            XCTFail("key details expected")
            return
        }
        let keys = [
            try Keypair(KeypairRealmObject(key1, passphrase: nil, source: .generated, user: userObject)),
            try Keypair(KeypairRealmObject(key2, passphrase: nil, source: .generated, user: userObject)),
        ]

        let keyStorage = EncryptedStorageMock()
        keyStorage.getKeypairsResult = keys

        let passPhraseService = PassPhraseServiceMock()
        passPhraseService.passPhrases = [
            PassPhrase(
                value: "this is a test phrase",
                fingerprintsOfAssociatedKey: ["F3CE6F66AFC486C83C03E01B4CCB28EA780DA902"],
                date: nil
            )
        ]

        let keyService = KeyService(
            storage: keyStorage,
            passPhraseService: passPhraseService
        )

        // act
        let result = try await keyService.getSigningKey(email: "bill@example.test")

        // assert
        XCTAssertEqual(result?.private, Self.privateKey2)
        XCTAssertEqual(result?.passphrase, "this is a test phrase")
    }

    func testGetSigningKeyNotFirstEmail() async throws {
        // arrange
        let userObject = UserRealmObject(name: "Bill", email: "bill@example.test", imap: nil, smtp: nil)

        guard let key = try await Core.shared.parseKeys(armoredOrBinary: Self.privateKey1.data()).keyDetails.first else {
            XCTFail("key details expected")
            return
        }
        let keys = [
            try Keypair(KeypairRealmObject(key, passphrase: nil, source: .generated, user: userObject))
        ]

        let keyStorage = EncryptedStorageMock()
        keyStorage.getKeypairsResult = keys

        let keyService = KeyService(
            storage: keyStorage,
            passPhraseService: PassPhraseServiceMock()
        )

        // act
        let result = try await keyService.getSigningKey(email: "bill@example.test")

        // assert
        XCTAssertEqual(result?.private, Self.privateKey1)
        XCTAssertNil(result?.passphrase)
    }

    private static let privateKey1 = "-----BEGIN PGP PRIVATE KEY BLOCK-----\r\nVersion: FlowCrypt iOS 0.2 Gmail Encryption\r\nComment: Seamlessly send and receive encrypted email\r\n\r\nxYYEYkKxgRYJKwYBBAHaRw8BAQdAx3pgx8MI/+ZSGsUf3XnDq+OJkxvrcYN6\r\nQLrT8uPZFQT+CQMIZNp2D4go9ErgX8Pa8G6Fs3zRE5C3DYtjNwOn7cJOciUB\r\nuGFSHo7aTClPcPAlP6zlG80gAx3G/ThRofReUpujWnVchc/1LFeAalVfmujq\r\nNs0VSmltIDxqaW1AZXhhbXBsZS5jb20+wncEEBYKAB8FAmJCsYEGCwkHCAMC\r\nBBUICgIDFgIBAhkBAhsDAh4BAAoJEJK9EV8qNujRMO8A/16sfxeVRUDFAabn\r\nlSf3MjqKVpwoFGuQx/7zh4aAvSEXAP9nS46A2HC1/zxdHYYuk84VnQjp9SkR\r\ntu4YCQp1dJVnB80YQmlsbCA8YmlsbEBleGFtcGxlLnRlc3Q+wnQEEBYKABwF\r\nAmJCsYEGCwkHCAMCBBUICgIDFgIBAhsDAh4BAAoJEJK9EV8qNujRXxUBAOOA\r\nYPAHj0OjiALpFCo5brefgifTehGBW0UJYlqtWR5UAP4xyoN50MmWs7jq0GAt\r\nIiCwfYgZpgmURWtKdctTnXflAceLBGJCsYESCisGAQQBl1UBBQEBB0BwnRbR\r\nlyRNibaEyMkoop002/6T+PlRSce2+IQb4IFWQQMBCAf+CQMILKLC+JBBtGng\r\nqKcco0V8CSfcP+tTgq8gF8IgZGssLjBQU74WEWCAL6ZBA/PolNwVYI0QwUfo\r\n0w6Ojz5vw8WVXlWlZjupyteHY5f93+IGfsJhBBgWCAAJBQJiQrGBAhsMAAoJ\r\nEJK9EV8qNujRjKYBALeXTFf/DU3tCPByHkeuBoqWgdEqbJriX28aEEkZx4M3\r\nAQCdMnMllKm5wot33MJIsswYbm6ID0K0UmXRyq0cG+EjCQ==\r\n=YRPK\r\n-----END PGP PRIVATE KEY BLOCK-----\r\n"

    private static let privateKey2 = "-----BEGIN PGP PRIVATE KEY BLOCK-----\r\nVersion: FlowCrypt iOS 0.2 Gmail Encryption\r\nComment: Seamlessly send and receive encrypted email\r\n\r\nxYYEYkKxTRYJKwYBBAHaRw8BAQdAuvZdxCfYvnM2fht9dgL6nuDahBQnsyjP\r\nDyG/QRBlJs/+CQMI+wwmQUcNGuTgn0bWKkSSIAKn7XYxlWmpY3StDPOuNVgy\r\nkBJuIr6likJ3UVS7anjMETcWVMfyR2ttrMw9emyzd8un5dyKXVQYl3EP6pOM\r\ndM0YQmlsbCA8YmlsbEBleGFtcGxlLnRlc3Q+wncEEBYKAB8FAmJCsU0GCwkH\r\nCAMCBBUICgIDFgIBAhkBAhsDAh4BAAoJEEzLKOp4DakCS8MBAKnF8mm+gsSf\r\nGonK+v2REzQvo+sdlNCuqYSAQYl70fH+AQDdrXToRpkb/0p4RWb8VFYuF1Ei\r\nhDaWpn2a8H5bn+FZCs0VSmltIDxqaW1AZXhhbXBsZS5jb20+wnQEEBYKABwF\r\nAmJCsU0GCwkHCAMCBBUICgIDFgIBAhsDAh4BAAoJEEzLKOp4DakCyiQBANhJ\r\n3wRttDVI5MxXUnTsGi+eqB3/WOrpWepI1aSHH2vhAQD/Iq65gvC7DcwGsh3u\r\nrCAtri5EO7aJAff5NAV7+1d+C8eLBGJCsU0SCisGAQQBl1UBBQEBB0CRbxu8\r\nboag3lA09BctR8ifS/b8itPcHEaAkxqZ51pWVgMBCAf+CQMIqw5bydUVF07g\r\nffse7BKV+7XKzbUSi6asMokSbOBYzM+sloNeTwKAq+WtFUTGmq7eatKIBUwh\r\neuTLA0AiXjGOWSy+L4C7bG+eHKW89RfFocJhBBgWCAAJBQJiQrFNAhsMAAoJ\r\nEEzLKOp4DakCOAwBANc6qYyvo8kVbf33fuWzahasNj4yPV0BHbEFfMu9Pr9L\r\nAQDv2InDwa30Jrf3MlsTjKGvuHCroqdGRzDWdBvpBGfpAA==\r\n=t3Az\r\n-----END PGP PRIVATE KEY BLOCK-----\r\n"
}
