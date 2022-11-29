//
//  ThreadDetailsDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 19.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import UIKit

extension ThreadMessageInfoCellNode.Input {
    init(threadMessage: ThreadDetailsViewController.Input, index: Int) {
        let sender = threadMessage.rawMessage.sender?.displayName ?? "message_unknown_sender".localized
        let recipientPrefix = "to".localized
        let recipientsList = threadMessage.rawMessage
            .allRecipients
            .map(\.shortName)
            .joined(separator: ", ")
        let recipientLabel = [recipientPrefix, recipientsList].joined(separator: " ")
        let date = DateFormatter().formatDate(threadMessage.rawMessage.date)
        let isMessageRead = threadMessage.rawMessage.isRead

        let style: NSAttributedString.Style = isMessageRead
            ? .regular(16)
            : .bold(16)

        let dateColor: UIColor = isMessageRead
            ? .lightGray
            : .main

        self.init(
            encryptionBadge: Self.makeEncryptionBadge(threadMessage),
            signatureBadge: Self.makeSignatureBadge(threadMessage),
            sender: .text(from: sender, style: style, color: .label),
            recipientLabel: .text(from: recipientLabel, style: style, color: .secondaryLabel),
            recipients: threadMessage.rawMessage.to.map(\.rawString),
            ccRecipients: threadMessage.rawMessage.cc.map(\.rawString),
            bccRecipients: threadMessage.rawMessage.bcc.map(\.rawString),
            date: .text(from: date, style: style, color: dateColor),
            isExpanded: threadMessage.isExpanded,
            shouldShowRecipientsList: threadMessage.shouldShowRecipientsList,
            buttonColor: .colorFor(darkStyle: .white, lightStyle: .main),
            index: index
        )
    }

    private static func makeEncryptionBadge(_ input: ThreadDetailsViewController.Input) -> BadgeNode.Input? {
        guard let type = input.processedMessage?.type else { return nil }

        let icon: String
        let text: String
        let color: UIColor

        switch type {
        case .error:
            icon = "lock.open"
            text = "message_decrypt_error".localized
            color = .errorColor
        case .encrypted:
            icon = "lock"
            text = "message_encrypted".localized
            color = .main
        default:
            icon = "lock.open"
            text = "message_not_encrypted".localized
            color = .errorColor
        }

        return BadgeNode.Input(
            icon: icon,
            text: NSAttributedString.text(from: text, style: .regular(12), color: .white),
            color: color,
            textAccessibilityIdentifier: "aid-encryption-badge"
        )
    }

    private static func makeSignatureBadge(_ input: ThreadDetailsViewController.Input) -> BadgeNode.Input? {
        guard let signature = input.processedMessage?.signature else {
            return nil
        }

        return BadgeNode.Input(
            icon: signature.icon,
            text: NSAttributedString.text(from: signature.message, style: .regular(12), color: .white),
            color: signature.color,
            textAccessibilityIdentifier: "aid-signature-badge"
        )
    }
}

extension AttachmentNode.Input {
    init(msgAttachment: MessageAttachment, index: Int) {
        self.init(
            name: msgAttachment.name
                .attributed(.regular(16), color: .textColor, alignment: .left),
            size: msgAttachment.formattedSize
                .attributed(.medium(12), color: .secondaryLabel, alignment: .left),
            index: index,
            isEncrypted: msgAttachment.isEncrypted
        )
    }
}
