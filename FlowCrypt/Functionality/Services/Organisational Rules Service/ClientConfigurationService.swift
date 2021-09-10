//
//  OrgRulesSignInPersmissionsService.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 15.07.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

// swiftlint:disable line_length
protocol ClientConfigurationServiceType {
    func checkShouldUseEKM() -> ClientConfigurationService.CheckForUsingEKMResult
}

class ClientConfigurationService: ClientConfigurationServiceType {

    private let organisationalRulesService: OrganisationalRulesServiceType

    init(organisationalRulesService: OrganisationalRulesServiceType = OrganisationalRulesService()) {
        self.organisationalRulesService = organisationalRulesService
    }

    /**
     * This method checks if the user is set up for using EKM, and if other client configuration is consistent with it.
     * There are three possible outcomes:
     *  1) EKM is in use because organisationalRules.isUsingKeyManager == true and other OrgRules are consistent with it (result: no error, use EKM)
     *  2) EKM is in use because organisationalRules.isUsingKeyManager == true and other OrgRules are NOT consistent with it (result: error)
     *  3) EKM is not in use because organisationalRules.isUsingKeyManager == false (result: normal login flow)
     */
    func checkShouldUseEKM() -> CheckForUsingEKMResult {
        let organisationalRules = organisationalRulesService.getSavedOrganisationalRulesForCurrentUser()
        if !organisationalRules.isUsingKeyManager {
            return .doesNotUseEKM
        }
        if !organisationalRules.mustAutoImportOrAutogenPrvWithKeyManager {
            return .inconsistentClientConfiguration(message: "organisational_rules_autoimport_or_autogen_with_private_key_manager_error".localized)
        }
        if organisationalRules.mustAutogenPassPhraseQuietly {
            return .inconsistentClientConfiguration(message: "organisational_rules_autogen_passphrase_quitely_error".localized)
        }
        if !organisationalRules.forbidStoringPassPhrase {
            return .inconsistentClientConfiguration(message: "organisational_rules_forbid_storing_passphrase_error".localized)
        }
        if organisationalRules.mustSubmitAttester {
            return .inconsistentClientConfiguration(message: "organisational_rules_must_submit_attester_error".localized)
        }
        return .usesEKM
    }
}
