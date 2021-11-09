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
    init(_ element: InboxRenderable) {
        let email = element.title
        let date = element.dateString
        let msg = element.subtitle
        let isMessageRead = element.isRead

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
            countText: {
                guard element.messageCount > 1 else { return nil }
                let count = element.messageCount > 99 ? "99+" : String(element.messageCount)
                return NSAttributedString.text(from: "(\(count))", style: style, color: textColor)
            }(),
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
            size: size,
            insets: UIEdgeInsets(
                top: size.height / 2,
                left: 0, bottom: 0, right: 0
            )
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
