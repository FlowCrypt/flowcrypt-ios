//
//  ComposeMessageServiceTests.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

private let recipientIdleState: RecipientState = .idle(ComposeViewDecorator.idleStateContext)

class ComposeMessageServiceTests: XCTestCase {

    var sut: ComposeMessageService!

    let recipients: [ComposeMessageRecipient] = [
        ComposeMessageRecipient(email: "test@gmail.com", state: recipientIdleState),
        ComposeMessageRecipient(email: "test2@gmail.com", state: recipientIdleState),
        ComposeMessageRecipient(email: "test3@gmail.com", state: recipientIdleState)
    ]
    let validKeyDetails = KeyStorageMock.createFakeKeyDetails(expiration: nil)

    var core = CoreComposeMessageMock()
    var keyStorage = KeyStorageMock()
    var contactsService = ContactsServiceMock()

    override func setUp() {
        super.setUp()
        let storageEncryptionKey = CoreHost().getSecureRandomByteNumberArray(64)!
        sut = ComposeMessageService(
            clientConfiguration: ClientConfiguration(
                raw: RawClientConfiguration()
            ),
            encryptedStorage: EncryptedStorage(
                storageEncryptionKey: Data(storageEncryptionKey)
            ),
            messageGateway: MessageGatewayMock(),
            draftGateway: DraftGatewayMock(),
            keyStorage: keyStorage,
            contactsService: contactsService,
            core: core
        )

        core.parseKeysResult = { data in
            guard !data.isEmpty else {
                return CoreRes.ParseKeys(format: .unknown, keyDetails: [])
            }
            return CoreRes.ParseKeys(format: .armored, keyDetails: [self.validKeyDetails])
        }
    }

    func testValidateMessageInputWithEmptyRecipients() async throws {
        do {
            _ = try await sut.validateAndProduceSendableMsg(
                input: ComposeMessageInput(type: .idle),
                contextToSend: ComposeMessageContext(
                    message: "",
                    recipients: [],
                    subject: nil
                ),
                email: "some@gmail.com",
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.emptyRecipient)
        }
    }

    func testValidateMessageInputWithWhitespaceRecipients() async {
        let recipients: [ComposeMessageRecipient] = [
            ComposeMessageRecipient(email: "   ", state: recipientIdleState),
            ComposeMessageRecipient(email: " ", state: recipientIdleState),
            ComposeMessageRecipient(email: "sdfff", state: recipientIdleState)
        ]
        do {
            _ = try await sut.validateAndProduceSendableMsg(
                input: ComposeMessageInput(type: .idle),
                contextToSend: ComposeMessageContext(
                    message: "",
                    recipients: recipients,
                    subject: nil
                ),
                email: "some@gmail.com",
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.emptyRecipient)
        }
    }

    func testValidateMessageInputWithEmptySubject() async {
        do {
            _ = try await sut.validateAndProduceSendableMsg(
                input: ComposeMessageInput(type: .idle),
                contextToSend: ComposeMessageContext(
                    message: "",
                    recipients: recipients,
                    subject: nil
                ),
                email: "some@gmail.com",
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.emptySubject)
        }
        do {
            _ = try await sut.validateAndProduceSendableMsg(
                input: ComposeMessageInput(type: .idle),
                contextToSend: ComposeMessageContext(
                    message: "",
                    recipients: recipients,
                    subject: ""
                ),
                email: "some@gmail.com",
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.emptySubject)
        }
        do {
            _ = try await sut.validateAndProduceSendableMsg(
                input: ComposeMessageInput(type: .idle),
                contextToSend: ComposeMessageContext(
                    message: "",
                    recipients: recipients,
                    subject: "     "
                ),
                email: "some@gmail.com",
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.emptySubject)
        }
    }

    func testValidateMessageInputWithEmptyMessage() async {
        do {
            _ = try await sut.validateAndProduceSendableMsg(
                input: ComposeMessageInput(type: .idle),
                contextToSend: ComposeMessageContext(
                    message: nil,
                    recipients: recipients,
                    subject: "Some subject"
                ),
                email: "some@gmail.com",
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.emptyMessage)
        }
        do {
            _ = try await sut.validateAndProduceSendableMsg(
                input: ComposeMessageInput(type: .idle),
                contextToSend: ComposeMessageContext(
                    message: "",
                    recipients: recipients,
                    subject: "Some subject"
                ),
                email: "some@gmail.com",
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.emptyMessage)
        }
        do {
            _ = try await sut.validateAndProduceSendableMsg(
                input: ComposeMessageInput(type: .idle),
                contextToSend: ComposeMessageContext(
                    message: "                  ",
                    recipients: recipients,
                    subject: "Some subject"
                ),
                email: "some@gmail.com",
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.emptyMessage)
        }
    }

    func testValidateMessageInputWithEmptyPublicKey() async {
        keyStorage.publicKeyResult = {
            nil
        }
        do {
            _ = try await sut.validateAndProduceSendableMsg(
                input: ComposeMessageInput(type: .idle),
                contextToSend: ComposeMessageContext(
                    message: "some message",
                    recipients: recipients,
                    subject: "Some subject"
                ),
                email: "some@gmail.com",
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.missedPublicKey)
        }
    }

    func testValidateMessageInputWithAllEmptyRecipientPubKeys() async {
        keyStorage.publicKeyResult = {
            "public key"
        }
        recipients.forEach { recipient in
            contactsService.retrievePubKeysResult = { _ in
                []
            }
        }
        do {
            _ = try await sut.validateAndProduceSendableMsg(
                input: ComposeMessageInput(type: .idle),
                contextToSend: ComposeMessageContext(
                    message: "some message",
                    recipients: recipients,
                    subject: "Some subject"
                ),
                email: "some@gmail.com",
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.noPubRecipients)
        }
    }

    func testValidateMessageInputWithExpiredRecipientPubKey() async {
        core.parseKeysResult = { _ in
            let keyDetails = KeyStorageMock.createFakeKeyDetails(expiration: Int(Date().timeIntervalSince1970 - 60))
            return CoreRes.ParseKeys(format: .armored, keyDetails: [keyDetails])
        }
        keyStorage.publicKeyResult = {
            "public key"
        }
        recipients.forEach { recipient in
            contactsService.retrievePubKeysResult = { _ in
                ["pubKey"]
            }
        }
        do {
            _ = try await sut.validateAndProduceSendableMsg(
                input: ComposeMessageInput(type: .idle),
                contextToSend: ComposeMessageContext(
                    message: "some message",
                    recipients: recipients,
                    subject: "Some subject"
                ),
                email: "some@gmail.com",
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.expiredKeyRecipients)
        }
    }

    func testValidateMessageInputWithRevokedRecipientPubKey() async {
        core.parseKeysResult = { _ in
            let keyDetails = KeyStorageMock.createFakeKeyDetails(expiration: nil, revoked: true)
            return CoreRes.ParseKeys(format: .armored, keyDetails: [keyDetails])
        }
        keyStorage.publicKeyResult = {
            "public key"
        }
        recipients.forEach { recipient in
            contactsService.retrievePubKeysResult = { _ in
                ["pubKey"]
            }
        }
        do {
            _ = try await sut.validateAndProduceSendableMsg(
                input: ComposeMessageInput(type: .idle),
                contextToSend: ComposeMessageContext(
                    message: "some message",
                    recipients: recipients,
                    subject: "Some subject"
                ),
                email: "some@gmail.com",
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.revokedKeyRecipients)
        }
    }

    func testValidateMessageInputWithValidAndInvalidRecipientPubKeys() async throws {
        core.parseKeysResult = { data in
            var allKeyDetails: [KeyDetails] = []
            let pubKeys = data.toStr()
                .split(separator: "\n")
                .map { String($0) }
            for pubKey in pubKeys {
                let isRevoked = pubKey == "revoked"
                let expiration: Int? = pubKey == "expired" ? Int(Date().timeIntervalSince1970 - 60) : nil
                allKeyDetails.append(KeyStorageMock.createFakeKeyDetails(
                    pub: pubKey,
                    expiration: expiration,
                    revoked: isRevoked
                ))
            }
            return CoreRes.ParseKeys(format: .armored, keyDetails: allKeyDetails)
        }
        keyStorage.publicKeyResult = {
            "public key"
        }
        recipients.forEach { recipient in
            contactsService.retrievePubKeysResult = { _ in
                ["revoked", "expired", "valid"]
            }
        }
        let message = "some message"
        let subject = "Some subject"
        let email = "some@gmail.com"
        let input = ComposeMessageInput(type: .idle)

        let result = try await sut.validateAndProduceSendableMsg(
            input: input,
            contextToSend: ComposeMessageContext(
                message: message,
                recipients: recipients,
                subject: subject
            ),
            email: email,
            signingPrv: nil
        )

        let expected = SendableMsg(
            text: message,
            to: recipients.map(\.email),
            cc: [],
            bcc: [],
            from: email,
            subject: subject,
            replyToMimeMsg: nil,
            atts: [],
            pubKeys: [
                "public key",
                "valid",
                "valid",
                "valid"
            ],
            signingPrv: nil)

        XCTAssertNotNil(result)
        XCTAssertEqual(result, expected)
    }

    func testValidateMessageInputWithoutOneRecipientPubKey() async throws {
        keyStorage.publicKeyResult = {
            "public key"
        }

        let recWithoutPubKey = recipients[0].email
        recipients.forEach { _ in
            contactsService.retrievePubKeysResult = { recipient in
                if recipient == recWithoutPubKey {
                    return []
                }
                return ["recipient pub key"]
            }
        }

        do {
            _ = try await sut.validateAndProduceSendableMsg(
                input: ComposeMessageInput(type: .idle),
                contextToSend: ComposeMessageContext(
                    message: "some message",
                    recipients: recipients,
                    subject: "Some subject"
                ),
                email: "some@gmail.com",
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.noPubRecipients)
        }
    }

    func testSuccessfulMessageValidation() async throws {
        keyStorage.publicKeyResult = {
            "public key"
        }
        recipients.enumerated().forEach { element, index in
            contactsService.retrievePubKeysResult = { recipient in
                ["pubKey"]
            }
        }
        let message = "some message"
        let subject = "Some subject"
        let email = "some@gmail.com"
        let input = ComposeMessageInput(type: .idle)

        let result = try await sut.validateAndProduceSendableMsg(
            input: input,
            contextToSend: ComposeMessageContext(
                message: message,
                recipients: recipients,
                subject: subject
            ),
            email: email,
            signingPrv: nil
        )

        let expected = SendableMsg(
            text: message,
            to: recipients.map(\.email),
            cc: [],
            bcc: [],
            from: email,
            subject: subject,
            replyToMimeMsg: nil,
            atts: [],
            pubKeys: [
                "public key",
                "pubKey",
                "pubKey",
                "pubKey"
            ],
            signingPrv: nil)

        XCTAssertNotNil(result)
        XCTAssertEqual(result, expected)
    }
}
