//
//  KeyServiceError.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum KeyServiceError: Error {
    case unexpected
    case parsingError
    case retrieve
    case missingCurrentUserEmail
    case expectedPrivateGotPublic
}

extension KeyServiceError: CustomStringConvertible {

    var description: String {
        let key: String
        switch self {
        case .unexpected:
            key = "keyServiceError_retrieve_unexpected"
        case .parsingError:
            key = "keyServiceError_retrieve_parse"
        case .retrieve:
            key = "keyServiceError_retrieve_error"
        case .missingCurrentUserEmail:
            key = "keyServiceError_missing_current_email"
        case .expectedPrivateGotPublic:
            key = "keyServiceError_retrieve_private"
        }
        return key.localized
    }
}
