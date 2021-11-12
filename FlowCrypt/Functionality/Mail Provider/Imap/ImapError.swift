//
//  ImapError.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum ImapError: Error {
    case noSession
    case providerError(Error)
    case missedMessageInfo(String)
}
