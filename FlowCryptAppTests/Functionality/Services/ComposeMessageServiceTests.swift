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
        ComposeMessageRecipient(email: "test@gmail.com", type: .to, state: recipientIdleState),
        ComposeMessageRecipient(email: "test2@gmail.com", type: .to, state: recipientIdleState),
        ComposeMessageRecipient(email: "test3@gmail.com", type: .to, state: recipientIdleState)
    ]
    let validKeyDetails = EncryptedStorageMock.createFakeKeyDetails(expiration: nil)
    let keypair = Keypair(
        primaryFingerprint: "",
        private: "",
        public: "public key",
        passphrase: nil,
        source: "",
        allFingerprints: [],
        allLongids: []
    )

    var core = CoreComposeMessageMock()
    var encryptedStorage = EncryptedStorageMock()
    var localContactsProvider = LocalContactsProviderMock()

    override func setUp() {
        super.setUp()
        sut = ComposeMessageService(
            clientConfiguration: ClientConfiguration(
                raw: RawClientConfiguration()
            ),
            encryptedStorage: encryptedStorage,
            messageGateway: MessageGatewayMock(),
            passPhraseService: PassPhraseServiceMock(),
            draftGateway: DraftGatewayMock(),
            localContactsProvider: localContactsProvider,
            sender: "some@gmail.com",
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
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.emptyRecipient)
        }
    }

    func testValidateMessageInputWithWhitespaceRecipients() async {
        let recipients: [ComposeMessageRecipient] = [
            ComposeMessageRecipient(email: "   ", type: .to, state: recipientIdleState),
            ComposeMessageRecipient(email: " ", type: .to, state: recipientIdleState),
            ComposeMessageRecipient(email: "sdfff", type: .to, state: recipientIdleState)
        ]
        do {
            _ = try await sut.validateAndProduceSendableMsg(
                input: ComposeMessageInput(type: .idle),
                contextToSend: ComposeMessageContext(
                    message: "",
                    recipients: recipients,
                    subject: nil
                ),
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
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.emptyMessage)
        }
    }

    func testValidateMessageInputWithEmptyPublicKey() async {
        encryptedStorage.getKeypairsResult = []
        do {
            _ = try await sut.validateAndProduceSendableMsg(
                input: ComposeMessageInput(type: .idle),
                contextToSend: ComposeMessageContext(
                    message: "some message",
                    recipients: recipients,
                    subject: "Some subject"
                ),
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.missingPublicKey)
        }
    }

    func testValidateMessageInputWithAllEmptyRecipientPubKeys() async {
        encryptedStorage.getKeypairsResult = [keypair]
        recipients.forEach { recipient in
            localContactsProvider.retrievePubKeysResult = { _ in
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
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.noPubRecipients)
        }
    }

    func testValidateMessageInputWithExpiredRecipientPubKey() async {
        core.parseKeysResult = { _ in
            let keyDetails = EncryptedStorageMock.createFakeKeyDetails(expiration: Int(Date().timeIntervalSince1970 - 60))
            return CoreRes.ParseKeys(format: .armored, keyDetails: [keyDetails])
        }
        encryptedStorage.getKeypairsResult = [keypair]
        recipients.forEach { recipient in
            localContactsProvider.retrievePubKeysResult = { _ in
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
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.expiredKeyRecipients)
        }
    }

    func testValidateMessageInputWithRevokedRecipientPubKey() async {
        core.parseKeysResult = { _ in
            let keyDetails = EncryptedStorageMock.createFakeKeyDetails(expiration: nil, revoked: true)
            return CoreRes.ParseKeys(format: .armored, keyDetails: [keyDetails])
        }
        encryptedStorage.getKeypairsResult = [keypair]
        recipients.forEach { recipient in
            localContactsProvider.retrievePubKeysResult = { _ in
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
                allKeyDetails.append(EncryptedStorageMock.createFakeKeyDetails(
                    pub: pubKey,
                    expiration: expiration,
                    revoked: isRevoked
                ))
            }
            return CoreRes.ParseKeys(format: .armored, keyDetails: allKeyDetails)
        }
        encryptedStorage.getKeypairsResult = [keypair]
        recipients.forEach { recipient in
            localContactsProvider.retrievePubKeysResult = { _ in
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
            signingPrv: nil
        )

        let expected = SendableMsg(
            text: message,
            html: nil,
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
            signingPrv: nil,
            password: nil)

        XCTAssertNotNil(result)
        XCTAssertEqual(result, expected)
    }

    func testValidateMessageInputWithoutOneRecipientPubKey() async throws {
        encryptedStorage.getKeypairsResult = [keypair]
        let recWithoutPubKey = recipients[0].email
        recipients.forEach { _ in
            localContactsProvider.retrievePubKeysResult = { recipient in
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
                signingPrv: nil
            )
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? MessageValidationError, MessageValidationError.noPubRecipients)
        }
    }

    func testSuccessfulMessageValidation() async throws {
        encryptedStorage.getKeypairsResult = [keypair]
        recipients.enumerated().forEach { element, index in
            localContactsProvider.retrievePubKeysResult = { recipient in
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
            signingPrv: nil
        )

        let expected = SendableMsg(
            text: message,
            html: nil,
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
            signingPrv: nil,
            password: nil)

        XCTAssertNotNil(result)
        XCTAssertEqual(result, expected)
    }
}
