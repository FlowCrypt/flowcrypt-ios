//
//  EnterpriseServerApiError.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 27/12/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum EnterpriseServerApiError: Error {
    case parse
    case emailFormat
    case noActiveFesUrl
}

extension EnterpriseServerApiError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .parse: return "organisational_rules_parse_error_description".localized
        case .emailFormat: return "organisational_rules_email_format_error_description".localized
        case .noActiveFesUrl: return "organisational_rules_fes_url_error_description".localized
        }
    }
}
