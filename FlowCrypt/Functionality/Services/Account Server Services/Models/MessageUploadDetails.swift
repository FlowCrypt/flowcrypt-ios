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
