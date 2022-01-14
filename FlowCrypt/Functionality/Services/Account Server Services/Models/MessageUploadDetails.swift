//
//  MessageUploadDetails.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 30/12/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct MessageUploadDetails: Encodable {
    let associateReplyToken: String
    let from: String
    let to: [String]
    let cc: [String]
    let bcc: [String]
}

extension MessageUploadDetails {
    init(from message: SendableMsg, replyToken: String) {
        self.associateReplyToken = replyToken
        self.from = message.from
        self.to = message.to
        self.cc = message.cc
        self.bcc = message.bcc
    }
}
