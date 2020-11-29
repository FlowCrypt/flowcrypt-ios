//
//  GmailServiceError.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

// TODO: - ANTON Handle common error
enum GmailServiceError: Error {
    /// Gmail API response parsing
    case failedToParseData(Any?)
    /// can't get GTLREncodeBase64 data
    case messageEncode
    /// message doesn't have any payload
    case missedMessagePayload
    /// Missed message part
    case missedMessageInfo(String)
}
