//
//  CreateKeyError.swift
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
        case let .weakPassPhrase(strength):
            return """
            Pass phrase strength: \(strength.word.word)
            crack time: \(strength.time)

            We recommend to use 5-6 unrelated words as your Pass Phrase.
            """
        case .missingUserEmail:
            return "backupManagerError_email".localized
        case .missingUserName:
            return "backupManagerError_name".localized
        case .doesntMatch:
            return "pass_phrase_match_error".localized
        case let .submitKey(error):
            return "submit_key_error".localized
                + "\n"
                + "\(error.errorMessage)"
        case .conformingPassPhraseError:
            return ""
        }
    }
}
