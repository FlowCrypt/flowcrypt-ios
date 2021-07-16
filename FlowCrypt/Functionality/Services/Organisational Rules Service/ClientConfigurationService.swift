//
//  OrgRulesSignInPersmissionsService.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 15.07.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

protocol ClientConfigurationServiceType {
    func checkForUsingKeyManager() -> String?
}

class ClientConfigurationService: ClientConfigurationServiceType {

    private let organisationalRulesService: OrganisationalRulesServiceType

    init(organisationalRulesService: OrganisationalRulesServiceType = OrganisationalRulesService()) {
        self.organisationalRulesService = organisationalRulesService
    }

    /// - Returns: Error message if not using key manager, returns nil if using key manager
    func checkForUsingKeyManager() -> String? {
        let organisationalRules = self.organisationalRulesService.getSavedOrganisationalRulesForCurrentUser()
        if organisationalRules.isUsingKeyManager {
            return nil
        }
        if !organisationalRules.mustAutoImportOrAutogenPrvWithKeyManager {
            return "organisational_rules_autoimport_or_autogen_with_private_key_manager_error".localized
        }
        if organisationalRules.mustAutogenPassPhraseQuietly {
            return "organisational_rules_autogen_passphrase_quitely_error".localized
        }
        if !organisationalRules.forbidStoringPassPhrase {
            return "organisational_rules_forbid_storing_passphrase_error".localized
        }
        if organisationalRules.mustSubmitAttester {
            return "organisational_rules_must_submit_attester_error".localized
        }
        if !organisationalRules.canCreateKeys {
            return "organisational_rules_can_create_keys_error".localized
        }
        return nil
    }
}
