//
//  Message.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST

// MARK: - Data Model
struct Message: Equatable {
    let date: Date
    let sender: String
    let subject: String
    let isMessageRead: Bool
    let size: Int

    init(date: Date, sender: String, subject: String, isMessageRead: Bool, size: Int) {
        self.date = date
        self.sender = sender
        self.subject = subject
        self.isMessageRead = isMessageRead
        self.size = size
    }
}

// MARK: - Imap
extension Message {
    init(imapMessage: MCOIMAPMessage) {
        self.init(
            date: imapMessage.header.date,
            sender: imapMessage.header.from.mailbox
                ?? imapMessage.header.sender.mailbox
                ?? "message_unknown_sender".localized,
            subject: imapMessage.header.subject ?? "message_missed_subject".localized,
            isMessageRead: imapMessage.flags.rawValue != 0,
            size: Int(imapMessage.size)
        )
    }
}

// MARK: - Gmail
extension Message {
    init?(gmailMessage: GTLRGmail_Message) {
        return nil
//        gmailMessage.payload?.
//        self.init(
//            date: gmailMessage.da,
//            sender: imapMessage.header.from.mailbox
//                ?? imapMessage.header.sender.mailbox
//                ?? "message_unknown_sender".localized,
//            subject: imapMessage.header.subject ?? "message_missed_subject".localized,
//            isMessageRead: imapMessage.flags.rawValue != 0,
//            size: Int(imapMessage.size)
//        )
    }
}
