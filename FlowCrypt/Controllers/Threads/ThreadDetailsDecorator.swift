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
            textColor = .red
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
