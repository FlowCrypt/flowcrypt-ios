//
//  KeyServiceErrorHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

enum CreateKeyError: Error {
    case weakPassPhrase(_ strength: CoreRes.ZxcvbnStrengthBar)
    /// Missing user email
    case missingUserEmail
    /// Missing user name
    case missingUserName
    /// Pass phrases don't match
    case doesntMatch
    /// Silent abort
    case conformingPassPhraseError
    /// Failed to submit key
    case submitKey(Error)
}

extension CreateKeyError: CustomStringConvertible {
    var description: String {
        switch self {
        case .weakPassPhrase(let strength):
            return """
            Pass phrase strength: \(strength.word.word)
            crack time: \(strength.time)

            We recommend to use 5-6 unrelated words as your Pass Phrase.
            """
        case .missingUserEmail:
            return "backupServiceError_email".localized
        case .missingUserName:
            return "backupServiceError_name".localized
        case .doesntMatch:
            return "pass_phrase_match_error".localized
        case .submitKey(let error):
            return "submit_key_error".localized
                + "\n"
                + "\(error.errorMessage)"
        case .conformingPassPhraseError:
            return ""
        }
    }
}

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
