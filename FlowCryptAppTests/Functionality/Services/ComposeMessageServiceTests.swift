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

        sut = ComposeMessageService(
            messageGateway: MessageGatewayMock(),
            draftGateway: DraftGatewayMock(),
            dataService: keyStorage,
            contactsService: contactsService,
            core: core
        )

        core.parseKeysResult = { _ in
            CoreRes.ParseKeys(format: .armored, keyDetails: [self.validKeyDetails])
        }
    }

    func testValidateMessageInputWithEmptyRecipients() async throws {
        do {
            let result = try await sut.validateAndProduceSendableMsg(
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
            let err = expectComposeMessageError(for: error)
            // todo
            XCTAssertEqual(err, MessageValidationError.emptyRecipient)
        }
    }

    func testValidateMessageInputWithWhitespaceRecipients() async {
        let recipients: [ComposeMessageRecipient] = [
            ComposeMessageRecipient(email: "   ", state: recipientIdleState),
            ComposeMessageRecipient(email: " ", state: recipientIdleState),
            ComposeMessageRecipient(email: "sdfff", state: recipientIdleState)
        ]
        let result = try await sut.validateAndProduceSendableMsg(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "",
                recipients: recipients,
                subject: nil
            ),
            email: "some@gmail.com",
            signingPrv: nil
        )

        var thrownError: Error?
        XCTAssertThrowsError(try result.get()) { thrownError = $0 }

        let error = expectComposeMessageError(for: thrownError)
        XCTAssertEqual(error, MessageValidationError.validationError(.emptyRecipient))
    }

    func testValidateMessageInputWithEmptySubject() async {
        func test() {
            var thrownError: Error?
            XCTAssertThrowsError(try result.get()) { thrownError = $0 }

            let error = expectComposeMessageError(for: thrownError)
            XCTAssertEqual(error, MessageValidationError.emptySubject)
        }

        var result = sut.validateAndProduceSendableMsg(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "",
                recipients: recipients,
                subject: nil
            ),
            email: "some@gmail.com",
            signingPrv: nil
        )

        test()

        result = sut.validateAndProduceSendableMsg(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "",
                recipients: recipients,
                subject: ""
            ),
            email: "some@gmail.com",
            signingPrv: nil
        )

        test()

        result = sut.validateAndProduceSendableMsg(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "",
                recipients: recipients,
                subject: "     "
            ),
            email: "some@gmail.com",
            signingPrv: nil
        )
    }

    func testValidateMessageInputWithEmptyMessage() async {
        func test() {
            var thrownError: Error?
            XCTAssertThrowsError(try result.get()) { thrownError = $0 }
            let error = expectComposeMessageError(for: thrownError)
            XCTAssertEqual(error, MessageValidationError.emptyMessage)
        }

        var result = try await sut.validateAndProduceSendableMsg(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: nil,
                recipients: recipients,
                subject: "Some subject"
            ),
            email: "some@gmail.com",
            signingPrv: nil
        )

        test()

        result = try await sut.validateAndProduceSendableMsg(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "",
                recipients: recipients,
                subject: "Some subject"
            ),
            email: "some@gmail.com",
            signingPrv: nil
        )

        test()

        result = try await sut.validateAndProduceSendableMsg(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "                  ",
                recipients: recipients,
                subject: "Some subject"
            ),
            email: "some@gmail.com",
            signingPrv: nil
        )

        test()
    }

    func testValidateMessageInputWithEmptyPublicKey() async {
        keyStorage.publicKeyResult = {
            nil
        }

        let result = try await sut.validateAndProduceSendableMsg(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "some message",
                recipients: recipients,
                subject: "Some subject"
            ),
            email: "some@gmail.com",
            signingPrv: nil
        )

        var thrownError: Error?
        XCTAssertThrowsError(try result.get()) { thrownError = $0 }
        let error = expectComposeMessageError(for: thrownError)
        XCTAssertEqual(error, MessageValidationError.missedPublicKey)
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

        let result = try await sut.validateAndProduceSendableMsg(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "some message",
                recipients: recipients,
                subject: "Some subject"
            ),
            email: "some@gmail.com",
            signingPrv: nil
        )

        var thrownError: Error?
        XCTAssertThrowsError(try result.get()) { thrownError = $0 }
        let error = expectComposeMessageError(for: thrownError)
        XCTAssertEqual(error, MessageValidationError.noPubRecipients)
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

        let result = try await sut.validateAndProduceSendableMsg(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "some message",
                recipients: recipients,
                subject: "Some subject"
            ),
            email: "some@gmail.com",
            signingPrv: nil
        )

        var thrownError: Error?
        XCTAssertThrowsError(try result.get()) { thrownError = $0 }
        let error = expectComposeMessageError(for: thrownError)
        XCTAssertEqual(error, MessageValidationError.validationError(.expiredKeyRecipients))
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

        let result = try await sut.validateAndProduceSendableMsg(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "some message",
                recipients: recipients,
                subject: "Some subject"
            ),
            email: "some@gmail.com",
            signingPrv: nil
        )

        var thrownError: Error?
        XCTAssertThrowsError(try result.get()) { thrownError = $0 }
        let error = expectComposeMessageError(for: thrownError)
        XCTAssertEqual(error, MessageValidationError.validationError(.revokedKeyRecipients))
    }

    func testValidateMessageInputWithValidAndInvalidRecipientPubKeys() async {
        core.parseKeysResult = { data in
            let pubKey = data.toStr()
            let isRevoked = pubKey == "revoked"
            let expiration: Int? = pubKey == "expired" ? Int(Date().timeIntervalSince1970 - 60) : nil
            let keyDetails = KeyStorageMock.createFakeKeyDetails(pub: pubKey,
                                                                 expiration: expiration,
                                                                 revoked: isRevoked)
            return CoreRes.ParseKeys(format: .armored, keyDetails: [keyDetails])
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

        let result = try? await sut.validateAndProduceSendableMsg(
            input: input,
            contextToSend: ComposeMessageContext(
                message: message,
                recipients: recipients,
                subject: subject
            ),
            email: email,
            signingPrv: nil
        ).get()

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
                "valid",
                "valid",
                "valid",
                "public key"
            ],
            signingPrv: nil)

        XCTAssertNotNil(result)
        XCTAssertEqual(result!, expected)
    }

    func testValidateMessageInputWithoutOneRecipientPubKey() async {
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

        let result = try await sut.validateAndProduceSendableMsg(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "some message",
                recipients: recipients,
                subject: "Some subject"
            ),
            email: "some@gmail.com",
            signingPrv: nil
        )

        var thrownError: Error?
        XCTAssertThrowsError(try result.get()) { thrownError = $0 }
        let error = expectComposeMessageError(for: thrownError)
        XCTAssertEqual(error, MessageValidationError.validationError(.noPubRecipients))
    }

    func testSuccessfulMessageValidation() async {
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

        let result = try? sut.validateMessage(
            input: input,
            contextToSend: ComposeMessageContext(
                message: message,
                recipients: recipients,
                subject: subject
            ),
            email: email,
            signingPrv: nil
        ).get()

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
                "pubKey",
                "pubKey",
                "pubKey",
                "public key"
            ],
            signingPrv: nil)

        XCTAssertNotNil(result)
        XCTAssertEqual(result!, expected)
    }

    private func expectComposeMessageError(for thrownError: Error?) -> ComposeMessageError {
        if let thrownError = thrownError as? ComposeMessageError { return thrownError
        } else {
            XCTFail()
            return ComposeMessageError.validationError(.internalError(""))
        }
    }
}
