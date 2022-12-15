//
//  KeyMethodsTest.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 20.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class KeyMethodsTest: XCTestCase {
    private let core: Core = .shared

    private var sut: KeyMethods!
    private var passPhrase = "Some long phrase"

    override func setUp() {
        sut = KeyMethods()
    }

    func testEmptyParsingKey() async throws {
        let emptyKeys: [KeyDetails] = []
        let result = try await sut.filterByPassPhraseMatch(keys: emptyKeys, passPhrase: passPhrase)

        XCTAssertTrue(result.isEmpty)
    }

    func testPassPublicKeyWhenExpectingPrivateForPassPhraseMatch() async throws {
        // private part = nil
        let keys = [
            KeyDetails(
                public: "Public part",
                private: nil,
                isFullyDecrypted: false,
                isFullyEncrypted: false,
                usableForEncryption: true,
                usableForSigning: true,
                ids: [
                    KeyId(longid: "longid", fingerprint: "fingerprint")
                ],
                created: 1,
                lastModified: nil,
                expiration: nil,
                users: [],
                algo: nil,
                revoked: false
            ),
            KeyDetails(
                public: "Public part2",
                private: nil,
                isFullyDecrypted: false,
                isFullyEncrypted: false,
                usableForEncryption: true,
                usableForSigning: true,
                ids: [
                    KeyId(longid: "longid 2", fingerprint: "fingerprint 2")
                ],
                created: 1,
                lastModified: nil,
                expiration: nil,
                users: [],
                algo: nil,
                revoked: false
            )
        ]
        do {
            _ = try await sut.filterByPassPhraseMatch(keys: keys, passPhrase: passPhrase)
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? KeypairError, KeypairError.expectedPrivateGotPublic)
        }
    }

    func testChooseSenderKeys() async throws {
        let keys = [keyPair, signOnlyKeyPair]
        let sender = "test@flowcrypt.com"

        let signingKeys = try await sut.chooseSenderKeys(
            for: .signing,
            keys: keys,
            senderEmail: sender
        )
        XCTAssertEqual(signingKeys.count, 2)

        let encryptionKeys = try await sut.chooseSenderKeys(
            for: .encryption,
            keys: keys,
            senderEmail: sender
        )
        XCTAssertEqual(encryptionKeys.count, 1)
    }
}

extension KeyMethodsTest {
    private var keyPair: Keypair {
        Keypair(
            primaryFingerprint: "5C0A43767E389D4A1F86C78B225BDA8A63EF422C",
            private: """
            -----BEGIN PGP PRIVATE KEY BLOCK-----
            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
            =a6LC
            -----END PGP PRIVATE KEY BLOCK-----
            """,
            public: """
            -----BEGIN PGP PUBLIC KEY BLOCK-----
            mQENBGOaNjoBCADAh3aRt+hVMQGgeeulW0nNqNcY2SPoFaiTsBuvHSLiqMtlMXdA
            Bta6YRJ9ftWiyXsNV/6yWYtHCcRWNY3Xq7GAHwxXCQzePzpM9tfCXUfJRFGMFhiu
            Q3/tUmvoSNrZVPgCl0l5BHGRszVdqEvW6VVYt3BIhJEsKDsnLZZnZxjF67zbzg6d
            wGSvw0XQjju0nulglQV2C6vVoc6pRorkjfP9Xfhi6cFWC15ubqCHU5Tuq/v0l0BX
            O/1B9POtFQGgEutCbmLIoHORg3uohJi8VrvPApNRMK29d7HWfPVz83iZeBQ6kw0w
            O7D840OfZrRKSMJgBi63C60t8ZSEsZBMUakvABEBAAG0HlRlc3QgVXNlciA8dGVz
            dEBmbG93Y3J5cHQuY29tPokBUQQTAQgAOxYhBFwKQ3Z+OJ1KH4bHiyJb2opj70Is
            BQJjmjY6AhsDBQsJCAcCAiICBhUKCQgLAgQWAgMBAh4HAheAAAoJECJb2opj70Is
            mZcIAKNJvPat++uZNK70DCxdCLn5PKsJ4mXSvibVlQIersGW1LZ0LK1fyzOCLJyp
            z3oKiapLW4EaJfJNidcp2ocjfjMCiqKsWkEAuVwttARRoLCkgMz+kQKp7lV4peAn
            W670wqTGGQ6zwv8VfslI6oUPDPvdQUugrov+9PkGSP4M39MsR8cqZmUm0dAasYy+
            3SCGebd8ZLdkLor61fyufjY0AePDROdq1P3/CTiGaE9thbZLnVV0+ROZHZmfm6oB
            D/qzdafeCdPsa5bVTNAOF48sfBOkh5tIMwe32xBXbQGi7binY3G4y2JiVKl1TTb5
            3pw4aHjAgmDwUM6YWv0R/mnnLSq5AQ0EY5o2OgEIALXiImrxKgo7d4ao3OIb2CEl
            KBNT1TOAHfw/nd4u/4WAtaioy4Mkrn+m/4VhnEIBTq4zdUlKT5HBUO06ydqo68kD
            zLSzS9fCLcuhWxSVtFP8KZ9/mwXE6DWUyIrYba8VOn2tgeLNeAajcsCaGUVY1VrU
            8D0mPnC8llN0qgYtPVYPhjPbUvByGGm2GEnlIv1MXLWHnn0iDNvPnOWYWMQJIqSh
            gGZsJ9r+MOx82G1Ry4ZU+ovMLRzT1HbZaTsmiv7xbqLxh/G15Fm+CzogHTDc2iSR
            ml0BFM2VLU8LV9M1V46VeTAGwif8nGf9RkppRGqC8MNYRMfZZZowOJxBkjr/2u8A
            EQEAAYkBNgQYAQgAIBYhBFwKQ3Z+OJ1KH4bHiyJb2opj70IsBQJjmjY6AhsMAAoJ
            ECJb2opj70IswKoH/2keGjMX7XbMlS7mnL5D7VNauE6FGJTJ3ztvxZQgPqcIAeTY
            PFQJ5cN0rvErYc7Gyuejr5Xu2+DwFqcKumkdb06wx0Eauftf6gMDLB+jAyhdWFYa
            7kdsJN77t4Bhx/9rYYLO4rfJ+wXJEpLZpLMxgXjzSLFsSB2vhWEQtLlryb4p+zLZ
            UVwGryxUd++omx6Fk5ju75nGOFEwNRJrNuCMjb5bobkaaGdO79ZOuLiCWR/LirtD
            wtJT/ohGJxfqbohasRUWV3qv0KrxHAQ1jIz4Mq0xvomh7OOiGFpBxcpdCmNsqXQ/
            LAsAJT47JwrrqHJBoMLZPesFvZmGtnrQB6CWu/c=
            =jv6S
            -----END PGP PUBLIC KEY BLOCK-----
            """,
            passphrase: "flowcrypt",
            source: "ekm",
            allFingerprints: [],
            allLongids: [],
            lastModified: 2,
            isRevoked: false
        )
    }

    private var signOnlyKeyPair: Keypair {
        Keypair(
            primaryFingerprint: "A2F4CCEE647FD6D1C573FA92D29690FBAC16EF19",
            private: """
            -----BEGIN PGP PRIVATE KEY BLOCK-----
            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
            =cENe
            -----END PGP PRIVATE KEY BLOCK-----
            """,
            public: """
            -----BEGIN PGP PUBLIC KEY BLOCK-----
            mQENBGOaLUEBCADOBFRuLs4N6tvCt6ICEi32Xtidexu45wPX5Rj06ht6bUfifqMY
            xBuHL9d2JTahQEV9w+YENxJbd6WLl9tuOs6ylmxLGt3DF2gaOa+fw7hwJUNlAFPd
            TCUaCYAGWsDld6+YS3pOakHhNRJaqIaOEKCKyKyq182TkMF2z9ELPhFoqOJSKoRL
            unBmBHB9OcrFIdtqNmHwG3raGgeHWe60Sx5fwb4cRY13xQccej6DAMwVDLncZXAm
            +RSyONPK9wBsQOA42mjWlwLe70lRgCDJYz1ozivAlwf/tsO4ug9fp2nJ3tYRAidm
            dokwoF8B44iYyZV4nbxt6R3kxJAAvTH1ZrBFABEBAAG0HlRlc3QgVXNlciA8dGVz
            dEBmbG93Y3J5cHQuY29tPokBUQQTAQgAOxYhBKL0zO5kf9bRxXP6ktKWkPusFu8Z
            BQJjmi1BAhsDBQsJCAcCAiICBhUKCQgLAgQWAgMBAh4HAheAAAoJENKWkPusFu8Z
            ZE8H/3J919HeoqFmFN59rjoix+iUrSaG8cf03c44y3mxl3+lriOYOzqZmslHxqGS
            X0hNwxES34fAWvR5KHWX/g1tdJeU637uWpVT4fJPIwziWD6KLfu0Gkdb0N27Rkn5
            X3G5fIdr2xAetnCoA+ybGUgwD6N+rAPyO3TZaeAy0SQyJQ/R/xbLdd23X7rsxqDO
            BI9hPGDmfAAXnRCI24A38qLaGY25LjpdBWPUHtOHhcy/010ywi3GJRGZuCicGkte
            voM9o+TUViLnQ5QYOeJd0L8c0YF2JP8CktsxiMwkwrlyUkwRAF7TCSMNsHQeMuKz
            cIgY4bMehsMrQtidvFDiiEtyNnw=
            =pMEd
            -----END PGP PUBLIC KEY BLOCK-----
            """,
            passphrase: "flowcrypt",
            source: "ekm",
            allFingerprints: [],
            allLongids: [],
            lastModified: 2,
            isRevoked: false
        )
    }
}
