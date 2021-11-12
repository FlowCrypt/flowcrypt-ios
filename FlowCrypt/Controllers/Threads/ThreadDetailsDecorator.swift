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
        let signature: String
        if let processedMessage = threadMessage.processedMessage, processedMessage.messageType == .encrypted {
            signature = processedMessage.signature.message
        } else {
            signature = "message_not_signed".localized
        }
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
            signature: NSAttributedString.text(from: signature, style: .regular(12), color: .white),
            signatureColor: threadMessage.processedMessage?.signature.color,
            signatureIcon: threadMessage.processedMessage?.signature.icon,
            sender: NSAttributedString.text(from: sender, style: style, color: textColor),
            date: NSAttributedString.text(from: date, style: style, color: dateColor),
            isExpanded: threadMessage.isExpanded,
            isEncrypted: threadMessage.processedMessage?.messageType == .encrypted,
            buttonColor: .messageButtonColor
        )
    }
}

extension UIColor {
    static var messageButtonColor: UIColor {
        .colorFor(darkStyle: .white, lightStyle: .main)
    }
}
