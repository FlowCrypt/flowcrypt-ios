//
//  BackupsManagerError.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum BackupsManagerError: Error {
    case parse
    case keyIsNotFullyEncrypted
}

extension BackupsManagerError: CustomStringConvertible {
    var description: String {
        switch self {
        case .parse:
            return "backupManagerError_parse".localized
        case .keyIsNotFullyEncrypted:
            return "backupManagerError_notEncrypted".localized
        }
    }
}
