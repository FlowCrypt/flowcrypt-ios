//
//  GmailApiError.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum GmailApiError: Error {
    /// Gmail API response parsing
    case failedToParseData(Any?)
    /// Can't get GTLREncodeBase64 data
    case messageEncode
    /// Message doesn't have any payload
    case missingMessagePayload
    /// Missing message part
    case missingMessageInfo(String)
    /// Provider Error
    case providerError(Error)
    /// Search backup error
    case searchBackup(Error)
    /// Pagination Error
    case paginationError(MessagesListPagination?)
    /// Invalid auth grant
    case invalidGrant(Error)
}

extension GmailApiError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failedToParseData:
            return "gmail_service_failed_to_parse_data_error_message".localized
        case .messageEncode:
            return "gmail_service_message_encode_error_message".localized
        case .missingMessagePayload:
            return "gmail_service_missing_message_payload_error_message".localized
        case let .missingMessageInfo(info):
            return "gmail_service_missing_message_info_error_message".localizeWithArguments(info)
        case let .providerError(error):
            return "gmail_service_provider_error_error_message".localizeWithArguments(error.localizedDescription)
        case let .paginationError(pagination):
            return "gmail_service_pagination_error".localizeWithArguments(String(describing: pagination))
        case let .searchBackup(error):
            return "gmail_service_search_backup_error_message".localizeWithArguments(error.localizedDescription)
        case .invalidGrant:
            return "gmail_service_invalid_grant_error_message".localized
        }
    }
}

extension GmailApiError {
    static func convert(from error: NSError) -> GmailApiError {
        switch error.code {
        case -10: // invalid_grant error code
            return .invalidGrant(error)
        default:
            return .providerError(error)
        }
    }
}
