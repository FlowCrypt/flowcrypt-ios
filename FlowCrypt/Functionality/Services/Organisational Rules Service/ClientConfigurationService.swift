//
//  OrgRulesSignInPersmissionsService.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 15.07.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

protocol ClientConfigurationServiceType {
    func checkForUsingKeyManager() -> ClientConfigurationService.CheckForUsingEKMResult
}

class ClientConfigurationService: ClientConfigurationServiceType {

    private let organisationalRulesService: OrganisationalRulesServiceType

    init(organisationalRulesService: OrganisationalRulesServiceType = OrganisationalRulesService()) {
        self.organisationalRulesService = organisationalRulesService
    }
    /// There are in fact three states:
    /// EKM is in use because organisationalRules.isUsingKeyManager == true and other OrgRules are consistent with it (result: no error, use EKM)
    /// EKM is in use because organisationalRules.isUsingKeyManager == true and other OrgRules are NOT consistent with it (result: error)
    /// EKM is not in use because organisationalRules.isUsingKeyManager == false (result: normal login flow)
    /// - Returns: Error message if not using key manager, returns nil if using key manager
    func checkForUsingKeyManager() -> CheckForUsingEKMResult {
        let organisationalRules = self.organisationalRulesService.getSavedOrganisationalRulesForCurrentUser()
        if !organisationalRules.isUsingKeyManager {
            return .skip
        }
        if !organisationalRules.mustAutoImportOrAutogenPrvWithKeyManager {
            return .error(message: "organisational_rules_autoimport_or_autogen_with_private_key_manager_error".localized)
        }
        if organisationalRules.mustAutogenPassPhraseQuietly {
            return .error(message: "organisational_rules_autogen_passphrase_quitely_error".localized)
        }
        if !organisationalRules.forbidStoringPassPhrase {
            return .error(message: "organisational_rules_forbid_storing_passphrase_error".localized)
        }
        if organisationalRules.mustSubmitAttester {
            return .error(message: "organisational_rules_must_submit_attester_error".localized)
        }
        return .useKeyManager
    }
}
