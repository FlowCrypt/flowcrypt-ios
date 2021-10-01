//
//  ClientConfigurationServiceResults.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 22.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum CheckEKMError: Error, CustomStringConvertible, Equatable {
    case urlNotValid
    case autoImportOrAutogenPrvWithKeyManager
    case autogenPassPhraseQuietly
    case forbidStoringPassPhrase
    case mustSubmitAttester

    var description: String {
        switch self {
        case .urlNotValid:
            return "organisational_rules_url_not_valid".localized
        case .autoImportOrAutogenPrvWithKeyManager:
            return "organisational_rules_autoimport_or_autogen_with_private_key_manager_error".localized
        case .autogenPassPhraseQuietly:
            return "organisational_rules_autogen_passphrase_quitely_error".localized
        case .forbidStoringPassPhrase:
            return "organisational_rules_forbid_storing_passphrase_error".localized
        case .mustSubmitAttester:
            return "organisational_rules_must_submit_attester_error".localized
        }
    }
}

extension ClientConfigurationService {
    enum CheckForUsingEKMResult: Equatable {
        case usesEKM
        case inconsistentClientConfiguration(checkError: CheckEKMError)
        case doesNotUseEKM
    }
}
