//
//  BackupServiceErrorHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit

struct BackupServiceErrorHandler: ErrorHandler {
    func handle(error: Error, for viewController: UIViewController) -> Bool {
        let errorMessage: String?

        switch error {
        case BackupServiceError.parse:
            errorMessage = "backupServiceError_parse"
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
