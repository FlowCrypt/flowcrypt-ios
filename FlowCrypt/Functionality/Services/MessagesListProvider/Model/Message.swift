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

// MARK: - Data Model
struct Message: Equatable {
    let identifier: Identifier
    let date: Date
    let sender: String?
    let subject: String?
    let isMessageRead: Bool
    let size: Int?

    init(identifier: Identifier, date: Date, sender: String?, subject: String?, isMessageRead: Bool, size: Int?) {
        self.identifier = identifier
        self.date = date
        self.sender = sender
        self.subject = subject
        self.isMessageRead = isMessageRead
        self.size = size
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
