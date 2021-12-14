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
        let userObject = UserRealmObject(name: "Bill", email: "bill@test.com", imap: nil, smtp: nil)

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
                fingerprintsOfAssociatedKey: ["4D5BFAD925F6ED3A43002B21127071C29744D9AC"],
                date: nil
            )
        ]

        let keyService = KeyService(
            storage: keyStorage,
            passPhraseService: passPhraseService,
            currentUserEmail: { "bill@test.com" }
        )

        // act
        let result = try await keyService.getSigningKey()

        // assert
        XCTAssertEqual(result?.private, Self.privateKey2)
        XCTAssertEqual(result?.passphrase, "this is a test phrase")
    }

    func testGetSigningKeyNotFirstEmail() async throws {
        // arrange
        let userObject = UserRealmObject(name: "Bill", email: "bill@test.com", imap: nil, smtp: nil)

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
            passPhraseService: PassPhraseServiceMock(),
            currentUserEmail: { "bill@test.com" }
        )

        // act
        let result = try await keyService.getSigningKey()

        // assert
        XCTAssertEqual(result?.private, Self.privateKey1)
        XCTAssertNil(result?.passphrase)
    }

    private static let privateKey1 = "-----BEGIN PGP PRIVATE KEY BLOCK-----\r\nVersion: FlowCrypt iOS 0.2 Gmail Encryption\r\nComment: Seamlessly send and receive encrypted email\r\n\r\nxYYEYWqrNRYJKwYBBAHaRw8BAQdAE5zIauV7xPHJhCwah+llfiES3E2bPWpl\r\nvmebwTR8+Fv+CQMI0eGd9iD/vfbgN3Cxh75EBA5uyu9nKLOQU/gVMJrELMKX\r\nxlQOVBJr/T8QMCmLTk8goDyPDJvsAVicThSpwtl8i04fCQL9HGRnD31Bi8IH\r\nPs0VSm9lIDxqb2VAZXhhbXBsZS5jb20+wncEEBYKAB8FAmFqqzUGCwkHCAMC\r\nBBUICgIDFgIBAhkBAhsDAh4BAAoJELOhqNZqZdBJPXgA/jwdE2547Pr8246X\r\nvfKYYnBQza68TLMTjbtJJnU9TDduAP4o8UpEY4SrwknjsfSXBnp4lU0vVLtn\r\nn8w8WHyol/EGAc0UQmlsbCA8YmlsbEB0ZXN0LmNvbT7CdAQQFgoAHAUCYWqr\r\nNQYLCQcIAwIEFQgKAgMWAgECGwMCHgEACgkQs6Go1mpl0En2iQD9FqE/t9wl\r\nap4MOVP4hB854NSwrGlR+n5zb3d/Sa4CPoABAMtSJ8NyFInDJhQQiKlPJ3P/\r\nnGS6FhmqekpgtRppkz4Hx4sEYWqrNRIKKwYBBAGXVQEFAQEHQMj2ddbJVEBW\r\n93NEtZM/HQ1TUedgsG4Z7mkBWFqPyvBJAwEIB/4JAwhb9dqp+4MPJ+Df52Bp\r\nBOvgBqxUkGnPlovRxQ9SMxalB9yMbZk/TcZI3W64Mm+4NjB4898w0/75/1xK\r\n2AbzssKk4+3WibQvWdN3I5AgUp7wwmEEGBYIAAkFAmFqqzUCGwwACgkQs6Go\r\n1mpl0En9DwD9Hty0s8PJne6jwaLsjYwaWsSHpu0DJmDBPL0tMto7TroA/R/w\r\nn9B42GzsElNs1CxbFhnpW3+Ra9uC55eroWtjJqUO\r\n=flUr\r\n-----END PGP PRIVATE KEY BLOCK-----\r\n"

    private static let privateKey2 = "-----BEGIN PGP PRIVATE KEY BLOCK-----\r\nVersion: FlowCrypt iOS 0.2 Gmail Encryption\r\nComment: Seamlessly send and receive encrypted email\r\n\r\nxYYEYWqrNRYJKwYBBAHaRw8BAQdANH7VeaCq+bTlzkF1xsrGXcLkqQbahIt6\r\nYsJqEZhCoRn+CQMIXoqISgIq7yHgQDXV3UGFfaXXUnXu1jtKEpFsl/XZxDAc\r\nHdwAVzYtpzNdUFZBMv/B5hCU2EIS/kEvOLjVZDewT9uzFb8RmqxtgoEtobHN\r\neM0UQmlsbCA8YmlsbEB0ZXN0LmNvbT7CdwQQFgoAHwUCYWqrNQYLCQcIAwIE\r\nFQgKAgMWAgECGQECGwMCHgEACgkQEnBxwpdE2axL8AD/Z0tcFarn5f+Rv1zt\r\naRZoldQuJPv8MphdDbzqhg/H5zgA/0M+b/XRtzKDmH31GPqRiM1S4yX19/hr\r\nhHpth7HM2cAJzRVKaW0gPGppbUBleGFtcGxlLmNvbT7CdAQQFgoAHAUCYWqr\r\nNQYLCQcIAwIEFQgKAgMWAgECGwMCHgEACgkQEnBxwpdE2ayzBAD/WDpY1O03\r\nnuMyuehkvc8GA6edjd1OONWpLR87/2FXE8sA/3otHmlKmEX+IVL2ZoSQa85P\r\n+MFZlraLxO3neEbJP1IAx4sEYWqrNRIKKwYBBAGXVQEFAQEHQLTVLP7+HOmo\r\nt3mPuII+Dxm+7xO/NLcHYzw1oq20YjdJAwEIB/4JAwjwQoOHTCn44+DPKeSc\r\nm5bKzLiZtUh6ad2zLK87h2LOX1eYv5NJCP2kqytksyo/sh1cQ/N3T76FEZwK\r\nCm+eHm3NsHPffzAdSZM5/SjV0Q0fwmEEGBYIAAkFAmFqqzUCGwwACgkQEnBx\r\nwpdE2aw9jgD/cPX1HJnX4mbuYLPq8FoC9HD8iS8OoUfhlMdHMWZkLMIBAMy3\r\nzJUdzt6t0ua/xJ2P7Wnbcn90nzvz8q95WePdmToP\r\n=5K6u\r\n-----END PGP PRIVATE KEY BLOCK-----\r\n"
}
