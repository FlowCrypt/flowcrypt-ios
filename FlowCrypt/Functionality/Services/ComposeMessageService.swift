//
//  ComposeMessageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.07.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Combine
import FlowCryptUI
import Foundation

struct ComposeMessageContext {
    var message: String?
    var recipients: [ComposeMessageRecipient] = []
    var subject: String?
}

struct ComposeMessageRecipient {
    let email: String
    var state: RecipientState
}

enum ComposeMessageError: Error, CustomStringConvertible {
    case validationError(MessageValidationError)
    case gatewayError(Error)

    // TODO: - ANTON - add proper description
    var description: String {
        switch self {
        case .validationError(let messageValidationError):
            return ""
        case .gatewayError(let error):
            return ""
        }
    }
}

enum MessageValidationError: Error {
    // showAlert(message: "compose_enter_recipient".localized)
    case emptyRecipient
    // showAlert(message: "compose_enter_subject".localized)
    case emptySubject
    // showAlert(message: "compose_enter_secure".localized)
    case emptyMessage

    // self.showAlert(message: "compose_no_pub_sender".localized)
    case missedPublicKey

    // showAlert(message: "Public key is missing")
    case missedRecipientPublicKey

    // showAlert(message: "Recipients should not be empty. Fail in checking")
    case internalError(String)
}

final class ComposeMessageService {
    private let messageGateway: MessageGateway
    private let dataService: KeyStorageType
    private let contactsService: ContactsServiceType
    private let core: Core

    init(
        messageGateway: MessageGateway = MailProvider.shared.messageSender,
        dataService: KeyStorageType = KeyDataStorage(),
        contactsService: ContactsServiceType = ContactsService(),
        core: Core = Core.shared
    ) {
        self.messageGateway = messageGateway
        self.dataService = dataService
        self.contactsService = contactsService
        self.core = core
    }

    func validateMessageInput(
        with recipients: [ComposeMessageRecipient],
        input: ComposeMessageInput,
        contextToSend: ComposeMessageContext,
        email: String,
        atts: [SendableMsg.Attachment]
    ) -> Result<SendableMsg, ComposeMessageError> {
        let emails = recipients.map(\.email)
        let hasContent = emails.filter { $0.hasContent }

        guard emails.count == hasContent.count else {
            return .failure(.validationError(.emptyRecipient))
        }

        guard input.isReply || contextToSend.subject?.hasContent ?? false else {
            return .failure(.validationError(.emptySubject))
        }

        guard let text = contextToSend.message, text.hasContent else {
            return .failure(.validationError(.emptyMessage))
        }

        let recipients = contextToSend.recipients

        guard recipients.isNotEmpty else {
            return .failure(.validationError(.internalError("Recipients should not be empty. Fail in checking")))
        }

        let subject = input.subjectReplyTitle
            ?? contextToSend.subject
            ?? "(no subject)"

        guard let myPubKey = self.dataService.publicKey() else {
            return .failure(.validationError(.missedPublicKey))
        }

        guard let allRecipientPubs = getPubKeys(for: recipients) else {
            return .failure(.validationError(.missedRecipientPublicKey))
        }

        let replyToMimeMsg = input.replyToMime
            .flatMap { String(data: $0, encoding: .utf8) }

        let msg = SendableMsg(
            text: text,
            to: recipients.map(\.email),
            cc: [],
            bcc: [],
            from: email,
            subject: subject,
            replyToMimeMsg: replyToMimeMsg,
            atts: atts,
            pubKeys: allRecipientPubs + [myPubKey]
        )

        return .success(msg)
    }

    private func getPubKeys(for recepients: [ComposeMessageRecipient]) -> [String]? {
        let pubKeys = recepients.map {
            ($0.email, contactsService.retrievePubKey(for: $0.email))
        }

        let emailsWithoutPubKeys = pubKeys.filter { $0.1 == nil }.map(\.0)

        guard emailsWithoutPubKeys.isEmpty else {
            // TODO: - ANTON - return error
//            showNoPubKeyAlert(for: emailsWithoutPubKeys)
            return nil
        }

        return pubKeys.compactMap(\.1)
    }

    func encryptAndSend(message: SendableMsg) -> AnyPublisher<Void, ComposeMessageError> {
        messageGateway.sendMail(mime: encryptMessage(with: message))
            .mapError { ComposeMessageError.gatewayError($0) }
            .eraseToAnyPublisher()
    }

    private func encryptMessage(with msg: SendableMsg) -> Data {
        do {
            return try core.composeEmail(msg: msg, fmt: MsgFmt.encryptInline, pubKeys: msg.pubKeys).mimeEncoded
        } catch {
            fatalError()
        }
    }
}

struct ComposedMessage {
    let email: String
    let pubkeys: [String]
    let subject: String
    let message: String
    let to: [String]
    let cc: [String]
    let bcc: [String]
    let atts: [SendableMsg.Attachment]
}

// TODO: - ANTON
// add tests for ComposeMessageService
