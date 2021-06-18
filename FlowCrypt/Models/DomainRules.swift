//
//  DomainRules.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 18.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

enum DomainRulesFlag: String, Codable {

    case noPRVBackup = "NO_PRV_BACKUP"
    case noPRVCreate = "NO_PRV_CREATE"
    case noKeyManagerPubLookup = "NO_KEY_MANAGER_PUB_LOOKUP"
    case PRVAutoimportOrAutogen = "PRV_AUTOIMPORT_OR_AUTOGEN"
    case passphraseQuietAutogen = "PASS_PHRASE_QUIET_AUTOGEN"
    case enforceAttesterSubmit = "ENFORCE_ATTESTER_SUBMIT"
    case noAttesterSubmit = "NO_ATTESTER_SUBMIT"
    case useLegacyAttesterSubmit = "USE_LEGACY_ATTESTER_SUBMIT"
    case defaultRememberPassphrase = "DEFAULT_REMEMBER_PASS_PHRASE"
    case hideArmorMeta = "HIDE_ARMOR_META"
}

struct DomainRules: Codable, Equatable {

    let flags: [DomainRulesFlag]?
    let customKeyserverUrl: String?
    let keyManagerUrl: String?
    let disallowAttesterSearchForDomains: [String]?
    let enforceKeygenAlgo: String?
    let enforceKeygenExpireMonths: Int?
}

// MARK: - Map from realm model
extension DomainRules {
    init?(_ object: DomainRulesObject?) {
        guard let unwrappedObject = object else {
            return nil
        }

        var decodedFlags: [String]?
        if let flagsData = object?.flags {
            decodedFlags = try? JSONDecoder().decode([String].self, from: flagsData)
        }

        var decodedDisallowAttesterSearchForDomains: [String]?
        if let disallowAttesterSearchForDomainsData = object?.disallowAttesterSearchForDomains {
            decodedDisallowAttesterSearchForDomains = try? JSONDecoder()
                .decode([String].self, from: disallowAttesterSearchForDomainsData)
        }

        self.init(
            flags: decodedFlags?.compactMap(DomainRulesFlag.init),
            customKeyserverUrl: unwrappedObject.customKeyserverUrl,
            keyManagerUrl: unwrappedObject.keyManagerUrl,
            disallowAttesterSearchForDomains: decodedDisallowAttesterSearchForDomains,
            enforceKeygenAlgo: unwrappedObject.enforceKeygenAlgo,
            enforceKeygenExpireMonths: unwrappedObject.enforceKeygenExpireMonths
        )
    }
}
