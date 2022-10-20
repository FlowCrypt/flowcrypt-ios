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
    case missingMessageInfo(String)
    case folderRequired
    case createSearchExpression
}

extension ImapError: CustomStringConvertible {
    var description: String {
        switch self {
        case .noSession:
            return "imap_error_no_session".localized
        case let .providerError(error):
            return "imap_error_provider".localizeWithArguments(error.localizedDescription)
        case let .missingMessageInfo(message):
            return "imap_error_msg_info".localizeWithArguments(message)
        case .folderRequired:
            return "imap_error_folder_required".localized
        case .createSearchExpression:
            return "imap_error_create_search_expression".localized
        }
    }
}
