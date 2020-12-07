//
//  Message.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import FlowCryptCommon
import GoogleAPIClientForREST

struct Message: Equatable {
    let identifier: Identifier
    let date: Date
    let sender: String?
    let subject: String?
    let size: Int?
    let labels: [MessageLabel]

    var isMessageRead: Bool {
        let types = labels.map(\.type)
        // imap 
        if types.contains(.none) {
            return false
        }
        // gmail
        if types.contains(.unread) {
            return false
        }
        return true
    }

    init(
        identifier: Identifier,
        date: Date,
        sender: String?,
        subject: String?,
        size: Int?,
        labels: [MessageLabel]
    ) {
        self.identifier = identifier
        self.date = date
        self.sender = sender
        self.subject = subject
        self.size = size
        self.labels = labels
    }
}

struct Identifier: Equatable {
    let stringId: String?
    let intId: Int?

    init(stringId: String? = nil, intId: Int? = nil) {
        self.stringId = stringId
        self.intId = intId
    }
}
