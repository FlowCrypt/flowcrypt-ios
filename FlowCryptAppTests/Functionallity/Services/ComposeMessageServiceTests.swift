//
//  ComposeMessageServiceTests.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import XCTest
@testable import FlowCrypt

private let recipientIdleState: RecipientState = .idle(ComposeViewDecorator.idleStateContext)

class ComposeMessageServiceTests: XCTestCase {

    var sut: ComposeMessageService!
    
    let recipients: [ComposeMessageRecipient] = [
        ComposeMessageRecipient(email: "test@gmail.com", state: recipientIdleState),
        ComposeMessageRecipient(email: "test2@gmail.com", state: recipientIdleState),
        ComposeMessageRecipient(email: "test3@gmail.com", state: recipientIdleState)
    ]
    
    var keyStorage = KeyStorageMock()
    var contactsService = ContactsServiceMock()
    
    override func setUp() {
        super.setUp()
        
        sut = ComposeMessageService(
            messageGateway: MessageGatewayMock(),
            dataService: keyStorage,
            contactsService: contactsService,
            core: CoreComposeMessageMock()
        )
    }
    
    func testValidateMessageInputWithEmptyRecipients() {
        let result = sut.validateMessage(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "",
                recipients: [],
                subject: nil
            ),
            email: "some@gmail.com"
        )

        var thrownError: Error?
        XCTAssertThrowsError(try result.get()) { thrownError = $0 }
    
        let error = expectComposeMessageError(for: thrownError)
        XCTAssertEqual(error, .validationError(.emptyRecipient))
    }
    
    func testValidateMessageInputWithWhitespaceRecipients() {
        let recipients: [ComposeMessageRecipient] = [
            ComposeMessageRecipient(email: "   ", state: recipientIdleState),
            ComposeMessageRecipient(email: " ", state: recipientIdleState),
            ComposeMessageRecipient(email: "sdfff", state: recipientIdleState)
        ]
        let result = sut.validateMessage(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "",
                recipients: recipients,
                subject: nil
            ),
            email: "some@gmail.com"
        )

        var thrownError: Error?
        XCTAssertThrowsError(try result.get()) { thrownError = $0 }
    
        let error = expectComposeMessageError(for: thrownError)
        XCTAssertEqual(error, .validationError(.emptyRecipient))
    }
    
    func testValidateMessageInputWithEmptySubject() {
        func test() {
            var thrownError: Error? =  nil
            XCTAssertThrowsError(try result.get()) { thrownError = $0 }
        
            let error = expectComposeMessageError(for: thrownError)
            XCTAssertEqual(error, .validationError(.emptySubject))
        }
        
        var result = sut.validateMessage(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "",
                recipients: recipients,
                subject: nil
            ),
            email: "some@gmail.com"
        )

        test()
        
        result = sut.validateMessage(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "",
                recipients: recipients,
                subject: ""
            ),
            email: "some@gmail.com"
        )
        
        test()
        
        result = sut.validateMessage(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "",
                recipients: recipients,
                subject: "     "
            ),
            email: "some@gmail.com"
        )
    }
    
    func testValidateMessageInputWithEmptyMessage() {
        func test() {
            var thrownError: Error?
            XCTAssertThrowsError(try result.get()) { thrownError = $0 }
            let error = expectComposeMessageError(for: thrownError)
            XCTAssertEqual(error, .validationError(.emptyMessage))
        }
        
        var result = sut.validateMessage(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: nil,
                recipients: recipients,
                subject: "Some subject"
            ),
            email: "some@gmail.com"
        )

        test()
        
        result = sut.validateMessage(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "",
                recipients: recipients,
                subject: "Some subject"
            ),
            email: "some@gmail.com"
        )
        
        test()
        
        result = sut.validateMessage(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "                  ",
                recipients: recipients,
                subject: "Some subject"
            ),
            email: "some@gmail.com"
        )
        
        test()
    }
    
    func testValidateMessageInputWithEmptyPublicKey() {
        keyStorage.publicKeyResult = {
            nil
        }
        
        let result = sut.validateMessage(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "some message",
                recipients: recipients,
                subject: "Some subject"
            ),
            email: "some@gmail.com"
        )
        
        var thrownError: Error?
        XCTAssertThrowsError(try result.get()) { thrownError = $0 }
        let error = expectComposeMessageError(for: thrownError)
        XCTAssertEqual(error, .validationError(.missedPublicKey))
    }
    
    func testValidateMessageInputWithAllEmptyRecipientPubKeys() {
        keyStorage.publicKeyResult = {
            "public key"
        }
    
        recipients.forEach { recipient in
            contactsService.retrievePubKeyResult = { _ in
                nil
            }
        } 
        
        let result = sut.validateMessage(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "some message",
                recipients: recipients,
                subject: "Some subject"
            ),
            email: "some@gmail.com"
        )
        
        var thrownError: Error?
        XCTAssertThrowsError(try result.get()) { thrownError = $0 }
        let error = expectComposeMessageError(for: thrownError)
        XCTAssertEqual(error, .validationError(.noPubRecipients(recipients.map(\.email))))
    }
    
    func testValidateMessageInputWithoutOneRecipientPubKey() {
        keyStorage.publicKeyResult = {
            "public key"
        }
    
        let recWithoutPubKey = recipients[0].email
        recipients.forEach { _ in
            contactsService.retrievePubKeyResult = { recipient in
                if recipient == recWithoutPubKey {
                    return nil
                }
                return "recipient pub key"
            }
        }
        
        let result = sut.validateMessage(
            input: ComposeMessageInput(type: .idle),
            contextToSend: ComposeMessageContext(
                message: "some message",
                recipients: recipients,
                subject: "Some subject"
            ),
            email: "some@gmail.com"
        )
        
        var thrownError: Error?
        XCTAssertThrowsError(try result.get()) { thrownError = $0 }
        let error = expectComposeMessageError(for: thrownError)
        XCTAssertEqual(error, .validationError(.noPubRecipients([recWithoutPubKey])))
    }
    
    func testSuccessfulMessageValidation() {
        keyStorage.publicKeyResult = {
            "public key"
        }
    
        recipients.enumerated().forEach { (element, index) in
            contactsService.retrievePubKeyResult = { recipient in
                "pubKey"
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
            email: email
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
            ])
        
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
