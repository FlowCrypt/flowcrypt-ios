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

    var hasCcOrBccRecipients: Bool {
        recipients.first(where: { $0.type == .cc || $0.type == .bcc }) != nil
    }

    var hasRecipientsWithoutPubKey: Bool {
        recipients.first { $0.keyState == .empty } != nil
    }

    var hasMessagePasswordIfNeeded: Bool {
        !hasRecipientsWithoutPubKey || hasMessagePassword
    }

    func recipients(type: RecipientType) -> [ComposeMessageRecipient] {
        recipients.filter { $0.type == type }
    }

    func recipientEmails(type: RecipientType) -> [String] {
        recipients(type: type).map(\.formatted)
    }

    func recipient(at index: Int, type: RecipientType) -> ComposeMessageRecipient? {
        recipients(type: type)[safe: index]
    }

    mutating func add(recipient: ComposeMessageRecipient) {
        recipients.append(recipient)
    }

    mutating func set(recipients: [ComposeMessageRecipient], for recipientType: RecipientType) {
        self.recipients.removeAll(where: { $0.type == recipientType })
        self.recipients += recipients
    }

    mutating func update(recipient: String, type: RecipientType, state: RecipientState) {
        guard let index = recipients.firstIndex(where: {
            $0.email == recipient && $0.type == type
        }) else { return }

        recipients[index].state = state
    }

    mutating func updateRecipient(email: String, state: RecipientState, keyState: PubKeyState?) {
        for index in recipients.indices {
            guard recipients[index].email == email else { return }
            recipients[index].state = state
            recipients[index].keyState = keyState
        }
    }

    mutating func remove(recipient: String, type: RecipientType) {
        recipients = recipients.filter { $0.email != recipient && $0.type != type }
    }

    mutating func update(recipient: String, state: RecipientState, keyState: PubKeyState?) {
        for index in recipients.indices {
            guard recipients[index].email == recipient else { return }

            recipients[index].state = state
            recipients[index].keyState = keyState
        }
    }
}
