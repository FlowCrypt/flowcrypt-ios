//
//  MessageSender.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

// TODO: - ANTON - Handle errors
enum MessageSenderError: Error {
    case failedToSendMessage(Error)
    case encode
}

protocol MessageSender {
    func sendMail(mime: Data) -> Promise<Void>
}
