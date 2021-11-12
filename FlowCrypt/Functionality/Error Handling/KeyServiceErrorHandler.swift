//
//  KeyServiceErrorHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

// KeyServiceError
struct KeyServiceErrorHandler: ErrorHandler {
    func handle(error: Error, for viewController: UIViewController) -> Bool {
        let errorMessage: String?
        switch error as? KeyServiceError {
        case .retrieve:
            errorMessage = "keyServiceError_retrieve_error"
        case .parsingError:
            errorMessage = "keyServiceError_retrieve_parse"
        case .unexpected:
            errorMessage = "keyServiceError_retrieve_unexpected"
        case .missingCurrentUserEmail:
            errorMessage = "keyServiceError_missing_current_email"
        default:
            errorMessage = nil
        }

        guard let message = errorMessage else { return false }

        viewController.showAlert(message: message.localized)

        return true
    }
}

// CreateKeyError
struct CreateKeyErrorHandler: ErrorHandler {
    func handle(error: Error, for viewController: UIViewController) -> Bool {
        let errorMessage: String?

        switch error as? CreateKeyError {
        case .weakPassPhrase(let strength):
            errorMessage = "Pass phrase strength: \(strength.word.word)\ncrack time: \(strength.time)\n\nWe recommend to use 5-6 unrelated words as your Pass Phrase."
        case .missedUserEmail:
            errorMessage = "backupServiceError_email".localized
        case .missedUserName:
            errorMessage = "backupServiceError_name".localized
        case .doesntMatch:
            errorMessage = "pass_phrase_match_error".localized
        case .conformingPassPhraseError:
            errorMessage = nil
        case .none:
            errorMessage = nil
        }

        guard let message = errorMessage else { return false }

        viewController.showAlert(message: message)

        return true
    }
}
