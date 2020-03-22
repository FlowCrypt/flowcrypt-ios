//
//  InboxViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 20/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import FlowCryptUI
import UIKit

extension InboxCellNode.Input {
    init(_ message: MCOIMAPMessage) {
        let email = message.header.from.displayName ?? message.header.sender.mailbox ?? "(unknown sender)"
        let date = DateFormatter().formatDate(message.header.date)
        let msg = message.header.subject ?? "No subject"
        let isMessageRead = message.flags.rawValue != 0

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
