//
//  CoreTypesTest.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 20/07/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class CoreTypesTest: XCTestCase {

    func test_sendable_msg_copy() {
        let msg = SendableMsg(
            text: "this is message",
            html: "<b>this is message</b>",
            to: ["some@gmail.com"],
            cc: [],
            bcc: [],
            from: "from@gmail.com",
            subject: "Some subject",
            replyToMsgId: nil,
            inReplyTo: nil,
            atts: [],
            pubKeys: ["public key"],
            signingPrv: nil,
            password: "123"
        )

        let copyBody = SendableMsgBody(
            text: "another message",
            html: "<b>another message</b>"
        )
        let copyAttachments = [SendableMsg.Attachment(
            name: "test.txt",
            type: "text/plain",
            base64: "test".data().base64EncodedString()
        )]
        let copyPubKeys = ["another key"]

        let msgCopy = msg.copy(
            body: copyBody,
            atts: copyAttachments,
            pubKeys: copyPubKeys
        )

        XCTAssertEqual(msgCopy.text, copyBody.text)
        XCTAssertEqual(msgCopy.html, copyBody.html)
        XCTAssertEqual(msgCopy.atts, copyAttachments)
        XCTAssertEqual(msgCopy.pubKeys, copyPubKeys)
        XCTAssertEqual(msgCopy.to, msg.to)
        XCTAssertEqual(msgCopy.from, msg.from)
        XCTAssertEqual(msgCopy.subject, msg.subject)
        XCTAssertEqual(msgCopy.password, msg.password)
    }

    func test_get_unique_by_fingerprint_by_prefering_latest_last_modified() {
        let firstKeyDetail = KeyDetails(
            public: "public1",
            private: "private1",
            isFullyDecrypted: false,
            isFullyEncrypted: false,
            usableForEncryption: true,
            usableForSigning: true,
            ids: [
                KeyId(
                    longid: "longid",
                    fingerprint: "SAMEFINGERPRINT"
                )
            ],
            created: 0,
            lastModified: nil,
            expiration: nil,
            users: [],
            algo: nil,
            revoked: false
        )
        let secondKeyDetail = KeyDetails(
            public: "public2",
            private: "private2",
            isFullyDecrypted: false,
            isFullyEncrypted: false,
            usableForEncryption: true,
            usableForSigning: true,
            ids: [
                KeyId(
                    longid: "longid2",
                    fingerprint: "SAMEFINGERPRINT"
                )
            ],
            created: 0,
            lastModified: 5000,
            expiration: nil,
            users: [],
            algo: nil,
            revoked: false
        )

        let given: [KeyDetails] = [
            firstKeyDetail,
            secondKeyDetail
        ]

        let result = given.getUniqueByFingerprintByPreferingLatestLastModified()

        XCTAssertEqual(
            result.count,
            1,
            "If the [KeyDetails] contains two keys with the same fingerprint, only one should be added"
        )
        XCTAssertEqual(result[0].public, "public2")
    }

    func test_key_ids_with_same_fingerprint() {
        let key1 = KeyId(
            longid: "longid1",
            fingerprint: "SAMEFINGERPRINT"
        )
        let key2 = KeyId(
            longid: "longid2",
            fingerprint: "SAMEFINGERPRINT"
        )
        let keys = [key1, key2]

        let result = keys.unique()

        XCTAssertEqual(result.count, 1)
    }
}
