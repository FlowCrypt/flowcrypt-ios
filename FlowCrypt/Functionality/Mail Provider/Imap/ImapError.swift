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
}

extension ImapError: CustomStringConvertible {
    var description: String {
        switch self {
        case .noSession:
            return "imap_error_no_session".localized
        case .providerError(let error):
            return "imap_error_provider".localizeWithArguments(error.localizedDescription)
        case .missingMessageInfo(let message):
            return "imap_error_msg_info".localizeWithArguments(message)
        }
    }
}
