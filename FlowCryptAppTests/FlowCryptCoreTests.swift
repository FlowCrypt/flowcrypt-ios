//
//  FlowCryptUITests.swift
//  FlowCryptUITests
//
//  Created by luke on 21/7/2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import XCTest
@testable import FlowCrypt

class FlowCryptCoreTests: XCTestCase {
    var core: Core!

    override func setUp() {
        super.setUp()
        // DispatchQueue.promises = .global() // this helps prevent Promise deadlocks - but currently Promises are not in use by tests
        core = Core.shared
        core.startInBackgroundIfNotAlreadyRunning()
        do {
            try core.blockUntilReadyOrThrow()
        } catch {
            XCTFail("Core did not get ready in time")
        }
    }

    // the tests below

    func testVersions() throws {
        let r = try core.version()
        XCTAssertEqual(r.app_version, "iOS 0.2")
    }

    func testGenerateKey() throws {
        let r = try core.generateKey(passphrase: "some pass phrase test", variant: KeyVariant.curve25519, userIds: [UserId(email: "first@domain.com", name: "First")])
        XCTAssertNotNil(r.key.private)
        XCTAssertEqual(r.key.isFullyDecrypted, false)
        XCTAssertEqual(r.key.isFullyEncrypted, true)
        XCTAssertNotNil(r.key.private!.range(of: "-----BEGIN PGP PRIVATE KEY BLOCK-----"))
        XCTAssertNotNil(r.key.public.range(of: "-----BEGIN PGP PUBLIC KEY BLOCK-----"))
        XCTAssertEqual(r.key.ids.count, 2)
    }

    func testZxcvbnStrengthBarWeak() throws {
        let r = try core.zxcvbnStrengthBar(passPhrase: "nothing much")
        XCTAssertEqual(r.word.word, CoreRes.ZxcvbnStrengthBar.WordDetails.Word.weak)
        XCTAssertEqual(r.word.pass, false)
        XCTAssertEqual(r.word.color, CoreRes.ZxcvbnStrengthBar.WordDetails.Color.red)
        XCTAssertEqual(r.word.bar, 10)
        XCTAssertEqual(r.time, "less than a second")
    }

    func testZxcvbnStrengthBarStrong() throws {
        let r = try core.zxcvbnStrengthBar(passPhrase: "this one is seriously over the top strong pwd")
        XCTAssertEqual(r.word.word, CoreRes.ZxcvbnStrengthBar.WordDetails.Word.perfect)
        XCTAssertEqual(r.word.pass, true)
        XCTAssertEqual(r.word.color, CoreRes.ZxcvbnStrengthBar.WordDetails.Color.green)
        XCTAssertEqual(r.word.bar, 100)
        XCTAssertEqual(r.time, "millennia")
    }

    func testParseKeys() throws {
        let r = try core.parseKeys(armoredOrBinary: TestData.k0.pub.data(using: .utf8)! + [10] + TestData.k1.prv.data(using: .utf8)!)
        XCTAssertEqual(r.format, CoreRes.ParseKeys.Format.armored)
        XCTAssertEqual(r.keyDetails.count, 2)
        // k0 k is public
        let k0 = r.keyDetails[0]
        XCTAssertNil(k0.private)
        XCTAssertNil(k0.isFullyDecrypted)
        XCTAssertNil(k0.isFullyEncrypted)
        XCTAssertEqual(k0.ids[0].longid, TestData.k0.longid)
        // k1 is private
        let k1 = r.keyDetails[1]
        XCTAssertNotNil(k1.private)
        XCTAssertEqual(k1.isFullyDecrypted, false)
        XCTAssertEqual(k1.isFullyEncrypted, true)
        XCTAssertEqual(k1.ids[0].longid, TestData.k1.longid)
        // todo - could test user ids
    }

    func testDecryptKeyWithCorrectPassPhrase() throws {
        let decryptKeyRes = try core.decryptKey(armoredPrv: TestData.k0.prv, passphrase: TestData.k0.passphrase)
        XCTAssertNotNil(decryptKeyRes.decryptedKey)
        // make sure indeed decrypted
        let parseKeyRes = try core.parseKeys(armoredOrBinary: decryptKeyRes.decryptedKey!.data(using: .utf8)!)
        XCTAssertEqual(parseKeyRes.keyDetails[0].isFullyDecrypted, true)
        XCTAssertEqual(parseKeyRes.keyDetails[0].isFullyEncrypted, false)
    }

    func testDecryptKeyWithWrongPassPhrase() throws {
        let k = try core.decryptKey(armoredPrv: TestData.k0.prv, passphrase: "wrong")
        XCTAssertNil(k.decryptedKey)
    }

    func testComposeEmailPlain() throws {
        let msg = SendableMsg(text: "this is the message", to: ["email@hello.com"], cc: [], bcc: [], from: "sender@hello.com", subject: "subj", replyToMimeMsg: nil, atts: [])
        let composeEmailRes = try core.composeEmail(msg: msg, fmt: MsgFmt.plain, pubKeys: nil)
        let mime = String(data: composeEmailRes.mimeEncoded, encoding: .utf8)!
        XCTAssertNil(mime.range(of: "-----BEGIN PGP MESSAGE-----")) // not encrypted
        XCTAssertNotNil(mime.range(of: msg.text)) // plain text visible
        XCTAssertNotNil(mime.range(of: "Subject: \(msg.subject)")) // has mime Subject header
        XCTAssertNil(mime.range(of: "In-Reply-To")) // Not a reply
    }

    func testComposeEmailEncryptInline() throws {
        let msg = SendableMsg(text: "this is the message", to: ["email@hello.com"], cc: [], bcc: [], from: "sender@hello.com", subject: "subj", replyToMimeMsg: nil, atts: [])
        let composeEmailRes = try core.composeEmail(msg: msg, fmt: MsgFmt.encryptInline, pubKeys: [TestData.k0.pub, TestData.k1.pub])
        let mime = String(data: composeEmailRes.mimeEncoded, encoding: .utf8)!
        XCTAssertNotNil(mime.range(of: "-----BEGIN PGP MESSAGE-----")) // encrypted
        XCTAssertNil(mime.range(of: msg.text)) // plain text not visible
        XCTAssertNotNil(mime.range(of: "Subject: \(msg.subject)")) // has mime Subject header
        XCTAssertNil(mime.range(of: "In-Reply-To")) // Not a reply
    }

    func testEndToEnd() throws {
        let passphrase = "some pass phrase test"
        let email = "e2e@domain.com"
        let text = "this is the encrypted e2e content"
        let generateKeyRes = try core.generateKey(passphrase: passphrase, variant: KeyVariant.curve25519, userIds: [UserId(email: email, name: "End to end")])
        let k = generateKeyRes.key
        let msg = SendableMsg(text: text, to: [email], cc: [], bcc: [], from: email, subject: "e2e subj", replyToMimeMsg: nil, atts: [])
        let mime = try core.composeEmail(msg: msg, fmt: MsgFmt.encryptInline, pubKeys: [k.public])
        let keys = [PrvKeyInfo(private: k.private!, longid: k.ids[0].longid, passphrase: passphrase)]
        let decrypted = try core.parseDecryptMsg(encrypted: mime.mimeEncoded, keys: keys, msgPwd: nil, isEmail: true)
        XCTAssertEqual(decrypted.text, text)
        XCTAssertEqual(decrypted.replyType, CoreRes.ReplyType.encrypted)
        XCTAssertEqual(decrypted.blocks.count, 1)
        let b = decrypted.blocks[0]
        XCTAssertNil(b.keyDetails) // should only be present on pubkey blocks
        XCTAssertNil(b.decryptErr) // was supposed to be a success
        XCTAssertEqual(b.type, MsgBlock.BlockType.plainHtml)
        XCTAssertNotNil(b.content.range(of: text)) // original text contained within the formatted html block
    }

    func testDecryptErrMismatch() throws {
        let key = PrvKeyInfo(private: TestData.k0.prv, longid: TestData.k0.longid, passphrase: TestData.k0.passphrase)
        let r = try core.parseDecryptMsg(encrypted: TestData.mismatchEncryptedMsg.data(using: .utf8)!, keys: [key], msgPwd: nil, isEmail: false)
        let decrypted = r
        XCTAssertEqual(decrypted.text, "")
        XCTAssertEqual(decrypted.replyType, CoreRes.ReplyType.plain) // replies to errors should be plain
        XCTAssertEqual(decrypted.blocks.count, 2)
        let contentBlock = decrypted.blocks[0]
        XCTAssertEqual(contentBlock.type, MsgBlock.BlockType.plainHtml)
        XCTAssertNotNil(contentBlock.content.range(of: "<body></body>")) // formatted content is empty
        let decryptErrBlock = decrypted.blocks[1]
        XCTAssertEqual(decryptErrBlock.type, MsgBlock.BlockType.decryptErr)
        XCTAssertNotNil(decryptErrBlock.decryptErr)
        let e = decryptErrBlock.decryptErr!
        XCTAssertEqual(e.error.type, MsgBlock.DecryptErr.ErrorType.keyMismatch)
    }

    func testException() throws {
        do {
            _ = try core.decryptKey(armoredPrv: "not really a key", passphrase: "whatnot")
            XCTFail("Should have thrown above")
        } catch let CoreError.exception(message) {
            XCTAssertNotNil(message.range(of: "Error: Misformed armored text"))
        }
    }
}
