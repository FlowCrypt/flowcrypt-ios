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
        let badge = element.badge
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
            emailText: email,
            countText: {
                guard element.messageCount > 1 else { return nil }
                let count = element.messageCount > 99 ? "99+" : String(element.messageCount)
                return NSAttributedString.text(from: "(\(count))", style: style, color: textColor)
            }(),
            dateText: NSAttributedString.text(from: date, style: style, color: dateColor),
            messageText: NSAttributedString.text(from: msg, style: style, color: textColor),
            badgeText: badge?.attributed(.regular(10), color: .white)
        )
    }
}

struct InboxViewDecorator {
    func emptyStateNodeInput(for size: CGSize, title: String, imageName: String) -> EmptyCellNode.Input {
        EmptyCellNode.Input(
            backgroundColor: .backgroundColor,
            title: title + " " + "empty".localized,
            size: size,
            imageName: imageName
        )
    }

    func searchEmptyStateNodeInput(for size: CGSize) -> TextCellNode.Input {
        TextCellNode.Input(
            backgroundColor: .backgroundColor,
            title: "search_empty".localized,
            withSpinner: false,
            size: size
        )
    }

    func initialNodeInput(for size: CGSize, withSpinner: Bool = true) -> TextCellNode.Input {
        TextCellNode.Input(
            backgroundColor: .backgroundColor,
            title: "",
            withSpinner: withSpinner,
            size: size
        )
    }
}
