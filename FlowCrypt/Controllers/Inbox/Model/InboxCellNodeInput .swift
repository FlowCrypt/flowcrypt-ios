//
//  InboxCellNodeInput .swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

struct InboxCellNodeInput {
    let emailText: NSAttributedString
    let dateText: NSAttributedString
    let messageText: NSAttributedString

    init(_ message: MCOIMAPMessage) {
        let email = message.header.sender.mailbox ?? "Empty"
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
            : .black

        emailText = NSAttributedString.text(from: email, style: style, color: textColor)
        dateText = NSAttributedString.text(from: date, style: style, color: dateColor)
        messageText = NSAttributedString.text(from: msg, style: style, color: textColor)
    }
}
