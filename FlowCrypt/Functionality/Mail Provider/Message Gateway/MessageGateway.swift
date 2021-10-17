//
//  MessageSender.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct MessageGatewayInput {
    let mime: Data
    let threadId: String?
}

protocol MessageGateway {
    func sendMail(input: MessageGatewayInput) async throws
}
