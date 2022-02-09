//
//  ComposeMessageContext.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 17/12/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct ComposeMessageContext: Equatable {
    var message: String?
    var recipients: [ComposeMessageRecipient]
    var subject: String?
    var attachments: [MessageAttachment]
    var messagePassword: String? {
        get {
            (_messagePassword ?? "").isNotEmpty ? _messagePassword : nil
        }
        set { _messagePassword = newValue }
    }

    private var _messagePassword: String?
}

extension ComposeMessageContext {
    init(message: String? = nil,
         recipients: [ComposeMessageRecipient] = [],
         subject: String? = nil,
         attachments: [MessageAttachment] = [],
         messagePassword: String? = nil
    ) {
        self.message = message
        self.recipients = recipients
        self.subject = subject
        self.attachments = attachments
        self.messagePassword = messagePassword
    }
}

extension ComposeMessageContext {
    var hasMessagePassword: Bool {
        messagePassword != nil
    }

    var hasRecipientsWithoutPubKey: Bool {
        recipients.first { $0.keyState == .empty } != nil
    }

    var hasMessagePasswordIfNeeded: Bool {
        !hasRecipientsWithoutPubKey || hasMessagePassword
    }

    func recipients(of type: RecipientType) -> [ComposeMessageRecipient] {
        recipients.filter { $0.type == type }
    }

    func recipientEmails(of type: RecipientType) -> [String] {
        recipients(of: type).map(\.email)
    }

    func recipient(at indexPath: IndexPath) -> ComposeMessageRecipient? {
        // TODO
        return nil
//        guard let recipientType = RecipientType(rawValue: indexPath.section) else { return nil }
//
//        switch recipientType {
//        case .to:
//            return to[indexPath.row]
//        case .cc:
//            return cc[indexPath.row]
//        case .bcc:
//            return bcc[indexPath.row]
//        }
    }

    mutating func add(recipient: ComposeMessageRecipient) {
        recipients.append(recipient)
    }

    mutating func set(recipients: [ComposeMessageRecipient], for recipientType: RecipientType) {
        // TODO:
//        switch recipientType {
//        case .to:
//            self.recipients[.to] = recipients
//        case .cc:
//            self.recipients[.cc] = recipients
//        case .bcc:
//            self.recipients[.bcc] = recipients
//        }
    }

    mutating func updateRecipient(email: String, state: RecipientState, keyState: PubKeyState?) {
        recipients.indices.forEach {
            guard recipients[$0].email == email else { return }
            recipients[$0].state = state
            recipients[$0].keyState = keyState
        }
    }

    mutating func updateRecipient(at indexPath: IndexPath, state: RecipientState, keyState: PubKeyState?) {
        // TODO
//        guard let recipientType = RecipientType(rawValue: indexPath.section) else { return }
//
//        switch recipientType {
//        case .to:
//            to[indexPath.row].state = state
//            to[indexPath.row].keyState = keyState
//        case .cc:
//            cc[indexPath.row].state = state
//            cc[indexPath.row].keyState = keyState
//        case .bcc:
//            bcc[indexPath.row].state = state
//            bcc[indexPath.row].keyState = keyState
//        }
    }

    mutating func removeRecipient(at indexPath: IndexPath) {
        // TODO
//        guard let recipientType = RecipientType(rawValue: indexPath.section) else { return }
//
//        switch recipientType {
//        case .to:
//            to.remove(at: indexPath.row)
//        case .cc:
//            cc.remove(at: indexPath.row)
//        case .bcc:
//            bcc.remove(at: indexPath.row)
//        }
    }

    mutating func updateRecipient(email: String, state: RecipientState, keyState: PubKeyState) {
        // TODO
//        RecipientType.allCases.forEach { type in
//            guard let index = recipients[type]?.firstIndex(where: { $0.email == email })
//            else { return }
//
//            recipients[type]?[index].state = state
//            recipients[type]?[index].keyState = keyState
//        }
    }
}
