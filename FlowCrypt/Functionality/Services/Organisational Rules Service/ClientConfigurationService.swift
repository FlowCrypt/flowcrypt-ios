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

        guard organisationalRules.isUsingKeyManager else {
            return .doesNotUseEKM
        }
        guard organisationalRules.isKeyManagerUrlValid else {
            return .inconsistentClientConfiguration(checkError: .urlNotValid)
        }
        if !organisationalRules.mustAutoImportOrAutogenPrvWithKeyManager {
            return .inconsistentClientConfiguration(checkError: .autoImportOrAutogenPrvWithKeyManager)
        }
        if organisationalRules.mustAutogenPassPhraseQuietly {
            return .inconsistentClientConfiguration(checkError: .autogenPassPhraseQuietly)
        }
        if !organisationalRules.forbidStoringPassPhrase {
            return .inconsistentClientConfiguration(checkError: .forbidStoringPassPhrase)
        }
        if organisationalRules.mustSubmitAttester {
            return .inconsistentClientConfiguration(checkError: .mustSubmitAttester)
        }
        return .usesEKM
    }
}
