//
//  BackupServiceError.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 14.10.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit

enum BackupServiceError: Error {
    case parse
    case emailNotFound
    case keyIsNotFullyEncrypted
}

struct BackupServiceErrorHandler: ErrorHandler {
    func handle(error: Error, for viewController: UIViewController) -> Bool {
        let errorMessage: String?

        switch error {
        case BackupServiceError.parse:
            errorMessage = "backupServiceError_parse"
        case BackupServiceError.emailNotFound:
            errorMessage = "backupServiceError_email"
        case BackupServiceError.keyIsNotFullyEncrypted:
            errorMessage = "backupServiceError_notEncrypted"
        default:
            errorMessage = nil
        }

        guard let message = errorMessage else { return false }

        viewController.showAlert(message: message.localized)

        return true
    }
}
