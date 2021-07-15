//
//  OrgRulesSignInPersmissionsService.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 15.07.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Promises

protocol OrganisationalRulesPersmissionsServiceType {
    func checkForUsingKeyManager() -> Promise<String?>
}

class OrganisationalRulesPersmissionsService: OrganisationalRulesPersmissionsServiceType {

    private let organisationalRulesService: OrganisationalRulesServiceType

    init(organisationalRulesService: OrganisationalRulesServiceType = OrganisationalRulesService()) {
        self.organisationalRulesService = organisationalRulesService
    }

    /// - Returns: Error message if not using key manager
    func checkForUsingKeyManager() -> Promise<String?> {
        Promise<String?> { resolve, _ in
            let organisationalRules = self.organisationalRulesService.getSavedOrganisationalRulesForCurrentUser()
            if organisationalRules.isUsingKeyManager {
                resolve(nil)
            }
            if !organisationalRules.mustAutoImportOrAutogenPrvWithKeyManager {
                resolve("organisational_rules_autoimport_or_autogen_with_private_key_manager_error".localized)
            }
            if organisationalRules.mustAutogenPassPhraseQuietly {
                resolve("organisational_rules_autogen_passphrase_quitely_error".localized)
            }
            if !organisationalRules.forbidStoringPassPhrase {
                resolve("organisational_rules_forbid_storing_passphrase_error".localized)
            }
            if organisationalRules.mustSubmitAttester {
                resolve("organisational_rules_must_submit_attester_error".localized)
            }
            if !organisationalRules.canCreateKeys {
                resolve("organisational_rules_can_create_keys_error".localized)
            }
        }
    }
}
