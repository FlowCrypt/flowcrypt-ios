//
//  GmailServiceError.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum GmailServiceError: Error {
    /// Gmail API response parsing
    case failedToParseData(Any?)
    /// can't get GTLREncodeBase64 data
    case messageEncode
    /// message doesn't have any payload
    case missedMessagePayload
    /// Missed message part
    case missedMessageInfo(String)
    /// Provider Error
    case providerError(Error)
    /// Empty or invalid backup search query
    case missedBackupQuery(Error)
}

extension GmailServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failedToParseData:
            return "gmail_service_failed_to_parse_data_error_message".localized
        case .messageEncode:
            return "gmail_service_message_encode_error_message".localized
        case .missedMessagePayload:
            return "gmail_service_missing_message_payload_error_message".localized
        case .missedMessageInfo(let info):
            return "gmail_service_missing_message_info_error_message".localizeWithArguments(info)
        case .providerError(let error):
            return "gmail_service_provider_error_error_message".localizeWithArguments(error.localizedDescription)
        case .missedBackupQuery(let error):
            return "gmail_service_missing_back_query_error_message".localizeWithArguments(error.localizedDescription)
        }
    }
}

extension GmailServiceError {
    var underlyingError: Error? {
        switch self {
        case .failedToParseData, .messageEncode, .missedMessagePayload, .missedMessageInfo:
            return nil
        case .providerError(let error):
            return error
        case .missedBackupQuery(let error):
            return error
        }
    }
}
