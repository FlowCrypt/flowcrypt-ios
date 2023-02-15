//
//  FlowCryptCoreTests.swift
//
//  Created by luke on 21/7/2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import FlowCryptCommon
import XCTest

final class FlowCryptCoreTests: XCTestCase {
    let core: Core = .shared

    private func testPerformance(maxDuration: Double, repeats: Int = 5, testBlock: () async throws -> Void) async {
        var durations: [Double] = []

        for _ in 1 ... repeats {
            let timer = TestTimer()
            timer.start()
            do {
                try await testBlock()
            } catch {}
            timer.stop()
            durations.append(timer.durationMs)
        }

        let average = durations.reduce(0, +) / Double(durations.count)
        XCTAssertLessThan(average, maxDuration)
    }

    // the tests below

    func testVersions() async throws {
        let r = try await core.version()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "[unknown version]"
        XCTAssertEqual(r.app_version, "iOS \(appVersion)")
    }

    func testGenerateKey() async throws {
        let r = try await core.generateKey(
            passphrase: "some pass phrase test",
            variant: KeyVariant.curve25519,
            userIds: [UserId(email: "first@domain.com", name: "First")]
        )
        XCTAssertNotNil(r.key.private)
        XCTAssertEqual(r.key.isFullyDecrypted, false)
        XCTAssertEqual(r.key.isFullyEncrypted, true)
        XCTAssertNotNil(r.key.private!.range(of: "-----BEGIN PGP PRIVATE KEY BLOCK-----"))
        XCTAssertNotNil(r.key.public.range(of: "-----BEGIN PGP PUBLIC KEY BLOCK-----"))
        XCTAssertEqual(r.key.ids.count, 2)
    }

    func testZxcvbnStrengthBarWeak() async throws {
        let r = try await core.zxcvbnStrengthBar(passPhrase: "nothing much")
        XCTAssertEqual(r.word.word, CoreRes.ZxcvbnStrengthBar.WordDetails.Word.weak)
        XCTAssertEqual(r.word.pass, false)
        XCTAssertEqual(r.word.color, CoreRes.ZxcvbnStrengthBar.WordDetails.Color.red)
        XCTAssertEqual(r.word.bar, 10)
        XCTAssertEqual(r.time, "less than a second")
    }

    func testZxcvbnStrengthBarStrong() async throws {
        let r = try await core.zxcvbnStrengthBar(passPhrase: "this one is seriously over the top strong pwd")
        XCTAssertEqual(r.word.word, CoreRes.ZxcvbnStrengthBar.WordDetails.Word.perfect)
        XCTAssertEqual(r.word.pass, true)
        XCTAssertEqual(r.word.color, CoreRes.ZxcvbnStrengthBar.WordDetails.Color.green)
        XCTAssertEqual(r.word.bar, 100)
        XCTAssertEqual(r.time, "millennia")
    }

    func testParseKeys() async throws {
        let r = try await core.parseKeys(armoredOrBinary: TestData.k0.public.data(using: .utf8)! + [10] + TestData.k1.private.data(using: .utf8)!)
        XCTAssertEqual(r.format, CoreRes.ParseKeys.Format.armored)
        XCTAssertEqual(r.keyDetails.count, 2)
        // k0 k is public
        let k0 = r.keyDetails[0]
        XCTAssertNil(k0.private)
        XCTAssertNil(k0.isFullyDecrypted)
        XCTAssertNil(k0.isFullyEncrypted)
        XCTAssertEqual(k0.lastModified, 1_543_925_225)
        XCTAssertNil(k0.expiration)
        // k1 is private
        let k1 = r.keyDetails[1]
        XCTAssertNotNil(k1.private)
        XCTAssertEqual(k1.isFullyDecrypted, false)
        XCTAssertEqual(k1.isFullyEncrypted, true)
        XCTAssertEqual(k1.lastModified, 1_563_630_809)
        XCTAssertNil(k1.expiration)
        // todo - could test user ids
    }

    func testDecryptKeyWithCorrectPassPhrase() async throws {
        let decryptKeyRes = try await core.decryptKey(armoredPrv: TestData.k0.private, passphrase: TestData.k0.passphrase!)
        XCTAssertNotNil(decryptKeyRes.decryptedKey)
        // make sure indeed decrypted
        let parseKeyRes = try await core.parseKeys(armoredOrBinary: decryptKeyRes.decryptedKey.data(using: .utf8)!)
        XCTAssertEqual(parseKeyRes.keyDetails[0].isFullyDecrypted, true)
        XCTAssertEqual(parseKeyRes.keyDetails[0].isFullyEncrypted, false)
    }

    func testDecryptKeyWithWrongPassPhrase() async {
        do {
            _ = try await core.decryptKey(armoredPrv: TestData.k0.private, passphrase: "wrong")
            XCTFail("Should have thrown above")
        } catch {
            Logger.logDebug("catched \(error)")
            return
        }
        XCTFail("Should have thrown above")
    }

    func testComposeEmailPlain() async throws {
        let msg = SendableMsg(
            text: "this is the message",
            html: "this is the message",
            to: ["email@hello.com"],
            cc: [],
            bcc: [],
            from: "sender@hello.com",
            subject: "subj",
            replyToMsgId: nil,
            inReplyTo: nil,
            atts: [],
            pubKeys: nil,
            signingPrv: nil,
            password: nil
        )
        let r = try await core.composeEmail(msg: msg, fmt: .plain)
        let mime = String(data: r.mimeEncoded, encoding: .utf8)!
        XCTAssertNil(mime.range(of: "-----BEGIN PGP MESSAGE-----")) // not encrypted
        XCTAssertNotNil(mime.range(of: msg.text)) // plain text visible
        XCTAssertNotNil(mime.range(of: "Subject: \(msg.subject)")) // has mime Subject header
        XCTAssertNil(mime.range(of: "In-Reply-To")) // Not a reply
    }

    func testComposeEmailEncryptInline() async throws {
        let msg = SendableMsg(
            text: "this is the message",
            html: "this is the message",
            to: ["email@hello.com"],
            cc: [],
            bcc: [],
            from: "sender@hello.com",
            subject: "subj",
            replyToMsgId: nil,
            inReplyTo: nil,
            atts: [],
            pubKeys: [TestData.k0.public, TestData.k1.public],
            signingPrv: nil,
            password: nil
        )
        let r = try await self.core.composeEmail(msg: msg, fmt: .encryptInline)
        let mime = String(data: r.mimeEncoded, encoding: .utf8)!
        XCTAssertNotNil(mime.range(of: "-----BEGIN PGP MESSAGE-----")) // encrypted
        XCTAssertNil(mime.range(of: msg.text)) // plain text not visible
        XCTAssertNotNil(mime.range(of: "Subject: \(msg.subject)")) // has mime Subject header
        XCTAssertNil(mime.range(of: "In-Reply-To")) // Not a reply
    }

    func testComposeEmailInlineWithAttachment() async throws {
        let initialFileName = "data.txt"
        let urlPath = URL(fileURLWithPath: Bundle(for: type(of: self))
            .path(forResource: "data", ofType: "txt")!)
        let fileData = try! Data(contentsOf: urlPath, options: .dataReadingMapped)
        let attachment = SendableMsg.Attachment(
            name: initialFileName, type: "text/plain",
            base64: fileData.base64EncodedString()
        )
        let msg = SendableMsg(
            text: "this is the message",
            html: "this is the message",
            to: ["email@hello.com"], cc: [], bcc: [],
            from: "sender@hello.com",
            subject: "subj",
            replyToMsgId: nil,
            inReplyTo: nil,
            atts: [attachment],
            pubKeys: [TestData.k0.public, TestData.k1.public],
            signingPrv: nil,
            password: nil
        )
        let r = try await core.composeEmail(msg: msg, fmt: .encryptInline)
        let mime = String(data: r.mimeEncoded, encoding: .utf8)!
        XCTAssertNil(mime.range(of: msg.text)) // text encrypted
        XCTAssertNotNil(mime.range(of: "Content-Type: application/pgp-encrypted")) // encrypted
        XCTAssertNotNil(mime.range(of: "name=\(attachment.name)")) // attachment
        XCTAssertNotNil(mime.range(of: "Subject: \(msg.subject)")) // has mime Subject header
    }

    func testComposeEmailWithSigningKey() async throws {
        // arrange
        let signingKey = TestData.k0

        let msg = SendableMsg(
            text: "this is the message",
            html: nil,
            to: ["email@hello.com"], cc: [], bcc: [],
            from: "sender@hello.com",
            subject: "Signed email",
            replyToMsgId: nil,
            inReplyTo: nil,
            atts: [],
            pubKeys: [TestData.k0.public],
            signingPrv: signingKey,
            password: nil
        )

        // act
        let r = try await core.composeEmail(msg: msg, fmt: .encryptInline)

        // assert
        let decrypted = try await core.parseDecryptMsg(
            encrypted: r.mimeEncoded,
            keys: [signingKey],
            msgPwd: nil,
            isMime: true,
            verificationPubKeys: [TestData.k0.public]
        )
        guard let verifyResult = decrypted.blocks.first?.verifyRes else {
            XCTFail("verify result expected")
            return
        }
        XCTAssertTrue(verifyResult.match ?? false)
        XCTAssertEqual(verifyResult.signer, "063635B3E33EB14C")
    }

    func testComposeEmailWithSigningKeyWithoutVerificationKey() async throws {
        // arrange
        let signingKey = TestData.k0

        let msg = SendableMsg(
            text: "this is the message",
            html: nil,
            to: ["email@hello.com"], cc: [], bcc: [],
            from: "sender@hello.com",
            subject: "Signed email",
            replyToMsgId: nil,
            inReplyTo: nil,
            atts: [],
            pubKeys: [TestData.k0.public],
            signingPrv: signingKey,
            password: nil
        )

        // act
        let r = try await core.composeEmail(msg: msg, fmt: .encryptInline)

        // assert
        let decrypted = try await core.parseDecryptMsg(
            encrypted: r.mimeEncoded,
            keys: [signingKey],
            msgPwd: nil,
            isMime: true,
            verificationPubKeys: []
        )

        guard let verifyResult = decrypted.blocks.first?.verifyRes else {
            XCTFail("verify result expected")
            return
        }

        XCTAssertNil(verifyResult.match)
        XCTAssertEqual(verifyResult.signer, "063635B3E33EB14C")
    }

    func testEndToEnd() async throws {
        let passphrase = "some pass phrase test"
        let email = "e2e@domain.com"
        let text = "this is the encrypted e2e content"
        let generateKeyRes = try await core.generateKey(
            passphrase: passphrase,
            variant: KeyVariant.curve25519,
            userIds: [UserId(email: email, name: "End to end")]
        )
        let msg = SendableMsg(
            text: text,
            html: text,
            to: [email],
            cc: [],
            bcc: [],
            from: email,
            subject: "e2e subj",
            replyToMsgId: nil,
            inReplyTo: nil,
            atts: [],
            pubKeys: [generateKeyRes.key.public],
            signingPrv: nil,
            password: nil
        )
        let mime = try await core.composeEmail(msg: msg, fmt: .encryptInline)
        let keys = [try Keypair(generateKeyRes.key, passPhrase: passphrase, source: "test")]
        let decrypted = try await core.parseDecryptMsg(encrypted: mime.mimeEncoded, keys: keys, msgPwd: nil, isMime: true, verificationPubKeys: [])
        XCTAssertEqual(decrypted.text, text)
        XCTAssertEqual(decrypted.replyType, ReplyType.encrypted)
        XCTAssertEqual(decrypted.blocks.count, 1)
        let b = decrypted.blocks[0]
        XCTAssertNil(b.keyDetails) // should only be present on pubkey blocks
        XCTAssertNil(b.decryptErr) // was supposed to be a success
        XCTAssertEqual(b.type, MsgBlock.BlockType.plainHtml)
        XCTAssertNotNil(b.content.range(of: text)) // original text contained within the formatted html block
    }

    func testDecryptErrMismatch() async throws {
        let key = TestData.k0
        let r = try await core.parseDecryptMsg(encrypted: TestData.mismatchEncryptedMsg.data(using: .utf8)!, keys: [key], msgPwd: nil, isMime: false, verificationPubKeys: [])
        let decrypted = r
        XCTAssertEqual(decrypted.text, "")
        XCTAssertEqual(decrypted.replyType, ReplyType.plain) // replies to errors should be plain
        XCTAssertEqual(decrypted.blocks.count, 2)
        let contentBlock = decrypted.blocks[0]
        XCTAssertEqual(contentBlock.type, MsgBlock.BlockType.plainHtml)
        XCTAssertNotNil(contentBlock.content.range(of: "<body></body>")) // formatted content is empty
        let decryptErrBlock = decrypted.blocks[1]
        XCTAssertEqual(decryptErrBlock.type, MsgBlock.BlockType.decryptErr)
        XCTAssertNotNil(decryptErrBlock.decryptErr)
        let e = decryptErrBlock.decryptErr!
        XCTAssertEqual(e.error.type, DecryptErr.ErrorType.keyMismatch)
    }

    func testEncryptFile() async throws {
        // Given
        let initialFileName = "data.txt"
        let urlPath = URL(fileURLWithPath: Bundle(for: type(of: self))
            .path(forResource: "data", ofType: "txt")!)
        let fileData = try! Data(contentsOf: urlPath, options: .dataReadingMapped)

        let passphrase = "some pass phrase test"
        let email = "e2e@domain.com"
        let generateKeyRes = try await core.generateKey(
            passphrase: passphrase,
            variant: KeyVariant.curve25519,
            userIds: [UserId(email: email, name: "End to end")]
        )

        // When
        let encrypted = try await core.encrypt(
            file: fileData,
            name: initialFileName,
            pubKeys: [generateKeyRes.key.public]
        )
        let decrypted = try await core.decryptFile(
            encrypted: encrypted,
            keys: [Keypair(generateKeyRes.key, passPhrase: passphrase, source: "test")],
            msgPwd: nil
        )

        // Then
        XCTAssertTrue(decrypted.decryptSuccess?.data == fileData)
        XCTAssertTrue(decrypted.decryptSuccess?.data.toStr() == fileData.toStr())
        XCTAssertTrue(decrypted.decryptSuccess?.name == initialFileName)
    }

    func testDecryptNotEncryptedFile() async throws {
        // Given
        let urlPath = URL(fileURLWithPath: Bundle(for: type(of: self))
            .path(forResource: "data", ofType: "txt")!)
        let fileData = try! Data(contentsOf: urlPath, options: .dataReadingMapped)

        let passphrase = "some pass phrase test"
        let email = "e2e@domain.com"
        let generateKeyRes = try await core.generateKey(
            passphrase: passphrase,
            variant: KeyVariant.curve25519,
            userIds: [UserId(email: email, name: "End to end")]
        )

        // When
        let decryptRes = try await core.decryptFile(
            encrypted: fileData,
            keys: [Keypair(generateKeyRes.key, passPhrase: passphrase, source: "test")],
            msgPwd: nil
        )

        // Then
        XCTAssertEqual(decryptRes.decryptErr?.error.type, DecryptErr.ErrorType.format)
    }

    func testDecryptWithNoKeys() async throws {
        // Given
        let initialFileName = "data.txt"
        let urlPath = URL(fileURLWithPath: Bundle(for: type(of: self))
            .path(forResource: "data", ofType: "txt")!)
        let fileData = try! Data(contentsOf: urlPath, options: .dataReadingMapped)

        let passphrase = "some pass phrase test"
        let email = "e2e@domain.com"
        let generateKeyRes = try await core.generateKey(
            passphrase: passphrase,
            variant: KeyVariant.curve25519,
            userIds: [UserId(email: email, name: "End to end")]
        )
        let k = generateKeyRes.key
        let encryptedFile = try await core.encrypt(
            file: fileData,
            name: initialFileName,
            pubKeys: [k.public]
        )
        let decryptResult = try await core.decryptFile(
            encrypted: encryptedFile,
            keys: [],
            msgPwd: nil
        )
        XCTAssertEqual(decryptResult.decryptErr!.error.type, DecryptErr.ErrorType.keyMismatch)
    }

    func testRsaPerformance() async throws {
        // Test decrypt key
        await testPerformance(maxDuration: 500) {
            _ = try await core.decryptKey(armoredPrv: TestData.k3rsa4096.private, passphrase: TestData.k3rsa4096.passphrase!)
        }

        // Test encrypt key
        let decryptKeyRes = try await core.decryptKey(armoredPrv: TestData.k3rsa4096.private, passphrase: TestData.k3rsa4096.passphrase!)
        await testPerformance(maxDuration: 800) {
            _ = try await core.encryptKey(armoredPrv: decryptKeyRes.decryptedKey, passphrase: TestData.k3rsa4096.passphrase!)
        }

        // Test verify key
        await testPerformance(maxDuration: 150) {
            try await core.verifyKey(armoredPrv: TestData.k3rsa4096.private)
        }

        // Test encrypt message
        await testPerformance(maxDuration: 150) {
            _ = try await core.encrypt(
                data: "Test email message".data(),
                pubKeys: [TestData.k3rsa4096.public],
                password: nil
            )
        }

        // Test decrypt message
        let encrypted = try await core.encrypt(
            data: "Test email message".data(),
            pubKeys: [TestData.k3rsa4096.public],
            password: nil
        )
        await testPerformance(maxDuration: 100) {
            _ = try await core.parseDecryptMsg(
                encrypted: encrypted,
                keys: [TestData.k3rsa4096],
                msgPwd: nil,
                isMime: true,
                verificationPubKeys: [TestData.k3rsa4096.public]
            )
        }

        // Test sign message
        let msg = SendableMsg(
            text: "this is the message",
            html: nil,
            to: ["email@recipient.test"],
            cc: [],
            bcc: [],
            from: "sender@sender.test",
            subject: "Signed email",
            replyToMsgId: nil,
            inReplyTo: nil,
            atts: [],
            pubKeys: [TestData.k3rsa4096.public],
            signingPrv: TestData.k3rsa4096,
            password: nil
        )
        await testPerformance(maxDuration: 1000) {
            _ = try await core.composeEmail(msg: msg, fmt: .encryptInline)
        }
    }

    func testDecryptEncryptedFile() async throws {
        // Given
        let initialFileName = "data.txt"
        let urlPath = URL(fileURLWithPath: Bundle(for: type(of: self))
            .path(forResource: "data", ofType: "txt")!)
        let fileData = try! Data(contentsOf: urlPath, options: .dataReadingMapped)

        let passphrase = "some pass phrase test"
        let email = "e2e@domain.com"
        let generateKeyRes = try await core.generateKey(
            passphrase: passphrase,
            variant: KeyVariant.curve25519,
            userIds: [UserId(email: email, name: "End to end")]
        )

        // When
        let encrypted = try await core.encrypt(
            file: fileData,
            name: initialFileName,
            pubKeys: [generateKeyRes.key.public]
        )
        let decrypted = try await core.decryptFile(
            encrypted: encrypted,
            keys: [Keypair(generateKeyRes.key, passPhrase: passphrase, source: "test")],
            msgPwd: nil
        )

        // Then
        XCTAssertEqual(decrypted.decryptSuccess?.name, initialFileName)
        XCTAssertEqual(decrypted.decryptSuccess?.data.count, fileData.count)
    }

    func testException() async throws {
        do {
            _ = try await core.decryptKey(armoredPrv: "not really a key", passphrase: "whatnot")
            XCTFail("Should have thrown above")
        } catch let CoreError.exception(message) {
            XCTAssertNotNil(message.range(of: "Error: Misformed armored text"))
        }
    }

    // This test always passes, even wrongly, on simulators running on a mac with 2 or fewer cores.
    // Behaves meaningfully on real iPhone or simulator on a mac with many cores
    func testCoreResponseCorrectnessUnderConcurrency() async throws {
        // given: a bunch of keys
        let pp = "this particular pass phrase is long enough"
        let k0 = try await core.generateKey(passphrase: pp, variant: KeyVariant.curve25519, userIds: [UserId(email: "k0@concurrent.test", name: "k0")])
        let k1 = try await core.generateKey(passphrase: pp, variant: KeyVariant.curve25519, userIds: [UserId(email: "k1@concurrent.test", name: "k1")])
        let k2 = try await core.generateKey(passphrase: pp, variant: KeyVariant.curve25519, userIds: [UserId(email: "k2@concurrent.test", name: "k2")])
        let k3 = try await core.generateKey(passphrase: pp, variant: KeyVariant.curve25519, userIds: [UserId(email: "k3@concurrent.test", name: "k3")])
        let k4 = try await core.generateKey(passphrase: pp, variant: KeyVariant.curve25519, userIds: [UserId(email: "k4@concurrent.test", name: "k4")])
        // when: keys are parsed concurrently
        async let p0prv = try await core.parseKeys(armoredOrBinary: k0.key.private!.data())
        async let p0pub = try await core.parseKeys(armoredOrBinary: k0.key.public.data())
        async let p1prv = try await core.parseKeys(armoredOrBinary: k1.key.private!.data())
        async let p1pub = try await core.parseKeys(armoredOrBinary: k1.key.public.data())
        async let p2prv = try await core.parseKeys(armoredOrBinary: k2.key.private!.data())
        async let p2pub = try await core.parseKeys(armoredOrBinary: k2.key.public.data())
        async let p3prv = try await core.parseKeys(armoredOrBinary: k3.key.private!.data())
        async let p3pub = try await core.parseKeys(armoredOrBinary: k3.key.public.data())
        async let p4prv = try await core.parseKeys(armoredOrBinary: k4.key.private!.data())
        async let p4pub = try await core.parseKeys(armoredOrBinary: k4.key.public.data())
        let prvs = try await [p0prv, p1prv, p2prv, p3prv, p4prv]
        let pubs = try await [p0pub, p1pub, p2pub, p3pub, p4pub]
        // then: parse results are not mixed up
        for (i, parsed) in prvs.enumerated() {
            XCTAssertEqual(
                parsed.keyDetails.first!.pgpUserEmails.first!,
                "k\(i)@concurrent.test"
            )
            XCTAssertNotNil(parsed.keyDetails.first?.private)
        }
        for (i, parsed) in pubs.enumerated() {
            XCTAssertEqual(
                parsed.keyDetails.first!.pgpUserEmails.first!,
                "k\(i)@concurrent.test"
            )
            XCTAssertNil(parsed.keyDetails.first?.private)
        }
    }
}
