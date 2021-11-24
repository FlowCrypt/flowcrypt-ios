//
//  ThreadDetailsDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 19.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import UIKit

extension ThreadMessageSenderCellNode.Input {
    init(threadMessage: ThreadDetailsViewController.Input) {
        let sender = threadMessage.rawMessage.sender ?? "message_unknown_sender".localized
        let date = DateFormatter().formatDate(threadMessage.rawMessage.date)
        let isMessageRead = threadMessage.rawMessage.isMessageRead

        let style: NSAttributedString.Style = isMessageRead
            ? .regular(17)
            : .bold(17)

        let dateColor: UIColor = isMessageRead
            ? .lightGray
            : .main

        let textColor: UIColor = isMessageRead
            ? .lightGray
            : .mainTextUnreadColor

        self.init(
            encryptionBadge: makeEncryptionBadge(threadMessage),
            signatureBadge: makeSignatureBadge(threadMessage),
            sender: NSAttributedString.text(from: sender, style: style, color: textColor),
            date: NSAttributedString.text(from: date, style: style, color: dateColor),
            isExpanded: threadMessage.isExpanded,
            buttonColor: .messageButtonColor
        )
    }
}

extension UIColor {
    static var messageButtonColor: UIColor {
        .colorFor(darkStyle: .white, lightStyle: .main)
    }
}

extension ProcessedMessage {
    var attributedMessage: NSAttributedString {
        let textColor: UIColor
        switch messageType {
        case .encrypted:
            textColor = .main
        case .error:
            textColor = .errorColor
        case .plain:
            textColor = .mainTextColor
        }
        return text.attributed(color: textColor)
    }
}

extension AttachmentNode.Input {
    init(msgAttachment: MessageAttachment) {
        self.init(
            name: msgAttachment.name
                .attributed(.regular(18), color: .textColor, alignment: .left),
            size: msgAttachment.humanReadableSizeString
                .attributed(.medium(12), color: .textColor, alignment: .left)
        )
    }
}

private func makeEncryptionBadge(_ input: ThreadDetailsViewController.Input) -> BadgeNode.Input {
    let icon: String
    let text: String
    let color: UIColor
    switch input.processedMessage?.messageType {
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
        color: color
    )
}

private func makeSignatureBadge(_ input: ThreadDetailsViewController.Input) -> BadgeNode.Input? {
    guard let signature = input.processedMessage?.signature else {
        return nil
    }

    return BadgeNode.Input(
        icon: signature.icon,
        text: NSAttributedString.text(from: signature.message, style: .regular(12), color: .white),
        color: signature.color
    )
}
