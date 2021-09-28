//
//  InboxViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 20/03/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import UIKit

extension InboxCellNode.Input {
    init(_ message: Message) {
        let email = message.sender ?? "message_unknown_sender".localized
        let date = DateFormatter().formatDate(message.date)
        let msg = message.subject ?? "message_missed_subject".localized
        let isMessageRead = message.isMessageRead

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
            emailText: NSAttributedString.text(from: email, style: style, color: textColor),
            dateText: NSAttributedString.text(from: date, style: style, color: dateColor),
            messageText: NSAttributedString.text(from: msg, style: style, color: textColor)
        )
    }
}

struct InboxViewDecorator {
    func emptyStateNodeInput(for size: CGSize, title: String) -> TextCellNode.Input {
        TextCellNode.Input(
            backgroundColor: .backgroundColor,
            title: "\(title) is empty",
            withSpinner: false,
            size: size
        )
    }

    func initialNodeInput(for size: CGSize) -> TextCellNode.Input {
        TextCellNode.Input(
            backgroundColor: .backgroundColor,
            title: "",
            withSpinner: true,
            size: size
        )
    }
}
