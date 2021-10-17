//
//  OrgRulesSignInPersmissionsService.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 15.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

// swiftlint:disable line_length
protocol ClientConfigurationEvaluatorType {
    func checkShouldUseEKM() -> ClientConfigurationEvaluator.CheckForUsingEKMResult
}

/// (tom) todo - this class should be removed,
/// and the method should be moved to ClientConfiguration class
class ClientConfigurationEvaluator: ClientConfigurationEvaluatorType {

    private let clientConfigurationService: ClientConfigurationServiceType

    init(clientConfigurationService: ClientConfigurationServiceType = ClientConfigurationService()) {
        self.clientConfigurationService = clientConfigurationService
    }

    /**
     * This method checks if the user is set up for using EKM, and if other client configuration is consistent with it.
     * There are three possible outcomes:
     *  1) EKM is in use because clientConfiguration.isUsingKeyManager == true and other client configs are consistent with it (result: no error, use EKM)
     *  2) EKM is in use because clientConfiguration.isUsingKeyManager == true and other client configs are NOT consistent with it (result: error)
     *  3) EKM is not in use because clientConfiguration.isUsingKeyManager == false (result: normal login flow)
     */
    func checkShouldUseEKM() -> CheckForUsingEKMResult {
        let clientConfiguration = clientConfigurationService.getSavedClientConfigurationForCurrentUser()

        guard clientConfiguration.isUsingKeyManager else {
            return .doesNotUseEKM
        }
        guard clientConfiguration.isKeyManagerUrlValid else {
            return .inconsistentClientConfiguration(checkError: .urlNotValid)
        }
        if !clientConfiguration.mustAutoImportOrAutogenPrvWithKeyManager {
            return .inconsistentClientConfiguration(checkError: .autoImportOrAutogenPrvWithKeyManager)
        }
        if clientConfiguration.mustAutogenPassPhraseQuietly {
            return .inconsistentClientConfiguration(checkError: .autogenPassPhraseQuietly)
        }
        if !clientConfiguration.forbidStoringPassPhrase {
            return .inconsistentClientConfiguration(checkError: .forbidStoringPassPhrase)
        }
        if clientConfiguration.mustSubmitAttester {
            return .inconsistentClientConfiguration(checkError: .mustSubmitAttester)
        }
        return .usesEKM
    }
}

enum ClientConfigurationServiceError: Error {
    case noCurrentUser
    case parse
    case emailFormat
}

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

extension ClientConfigurationEvaluator {
    enum CheckForUsingEKMResult: Equatable {
        case usesEKM
        case inconsistentClientConfiguration(checkError: CheckEKMError)
        case doesNotUseEKM
    }
}
