//
//  MessageUploadRequest.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 27/12/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct MessageUploadRequest {
    let associateReplyToken: String
    let from: String
    let to: [String]
    let cc: [String]
    let bcc: [String]
}
