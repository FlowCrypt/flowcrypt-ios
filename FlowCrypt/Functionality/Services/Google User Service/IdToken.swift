//
//  IdToken.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 07.12.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct IdToken: Codable {
    let exp: Int
}

extension IdToken {
    var expiryDuration: Double {
        Date(timeIntervalSince1970: Double(exp)).timeIntervalSinceNow
    }
}

enum IdTokenError: Error, CustomStringConvertible {
    case missingToken, invalidJWTFormat, invalidBase64EncodedData

    var description: String {
        switch self {
        case .missingToken:
            return "id_token_missing_error_description".localized
        case .invalidJWTFormat, .invalidBase64EncodedData:
            return "id_token_invalid_error_description".localized
        }
    }
}
