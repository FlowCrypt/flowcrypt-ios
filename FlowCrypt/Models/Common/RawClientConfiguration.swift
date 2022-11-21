//
//  ClientConfiguration.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 18.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum ClientConfigurationFlag: String, Codable {

    case noPrivateKeyBackup = "NO_PRV_BACKUP"
    case noPrivateKeyCreate = "NO_PRV_CREATE"
    case noKeyManagerPubLookup = "NO_KEY_MANAGER_PUB_LOOKUP"
    case privateKeyAutoimportOrAutogen = "PRV_AUTOIMPORT_OR_AUTOGEN"
    case passphraseQuietAutogen = "PASS_PHRASE_QUIET_AUTOGEN"
    case enforceAttesterSubmit = "ENFORCE_ATTESTER_SUBMIT"
    case noAttesterSubmit = "NO_ATTESTER_SUBMIT"
    case useLegacyAttesterSubmit = "USE_LEGACY_ATTESTER_SUBMIT"
    case defaultRememberPassphrase = "DEFAULT_REMEMBER_PASS_PHRASE"
    case hideArmorMeta = "HIDE_ARMOR_META"
    case forbidStoringPassphrase = "FORBID_STORING_PASS_PHRASE"

    case unknown
}

struct RawClientConfiguration: Codable, Equatable {

    let flags: [ClientConfigurationFlag]?
    let customKeyserverUrl: String?
    let keyManagerUrl: String?
    let fesUrl: String?
    let allowAttesterSearchOnlyForDomains: [String]?
    let inMemoryPassPhraseSessionLength: Int?
    let disallowAttesterSearchForDomains: [String]?
    let enforceKeygenAlgo: String?
    let enforceKeygenExpireMonths: Int?

    init(
        flags: [ClientConfigurationFlag]? = nil,
        customKeyserverUrl: String? = nil,
        keyManagerUrl: String? = nil,
        fesUrl: String? = nil,
        inMemoryPassPhraseSessionLength: Int? = nil,
        allowAttesterSearchOnlyForDomains: [String]? = nil,
        disallowAttesterSearchForDomains: [String]? = nil,
        enforceKeygenAlgo: String? = nil,
        enforceKeygenExpireMonths: Int? = nil
    ) {
        self.flags = flags
        self.customKeyserverUrl = customKeyserverUrl
        self.keyManagerUrl = keyManagerUrl
        self.fesUrl = fesUrl
        self.inMemoryPassPhraseSessionLength = inMemoryPassPhraseSessionLength
        self.allowAttesterSearchOnlyForDomains = allowAttesterSearchOnlyForDomains
        self.disallowAttesterSearchForDomains = disallowAttesterSearchForDomains
        self.enforceKeygenAlgo = enforceKeygenAlgo
        self.enforceKeygenExpireMonths = enforceKeygenExpireMonths
    }
}

// MARK: - Empty model
extension RawClientConfiguration {
    static var empty: RawClientConfiguration {
        return RawClientConfiguration()
    }
}

// MARK: - Map from realm model
extension RawClientConfiguration {
    init?(_ object: ClientConfigurationRealmObject?) {
        guard let unwrappedObject = object else {
            return nil
        }

        var decodedFlags: [String]?
        if let flagsData = object?.flags {
            decodedFlags = try? JSONDecoder().decode([String].self, from: flagsData)
        }

        self.init(
            flags: decodedFlags?.compactMap(ClientConfigurationFlag.init),
            customKeyserverUrl: unwrappedObject.customKeyserverUrl,
            keyManagerUrl: unwrappedObject.keyManagerUrl,
            fesUrl: unwrappedObject.fesUrl,
            inMemoryPassPhraseSessionLength: object?.inMemoryPassPhraseSessionLength,
            allowAttesterSearchOnlyForDomains: try? object?.allowAttesterSearchOnlyForDomains.ifNotNil {
                try JSONDecoder().decode([String].self, from: $0)
            },
            disallowAttesterSearchForDomains: try? object?.disallowAttesterSearchForDomains.ifNotNil {
                try JSONDecoder().decode([String].self, from: $0)
            },
            enforceKeygenAlgo: unwrappedObject.enforceKeygenAlgo,
            enforceKeygenExpireMonths: unwrappedObject.enforceKeygenExpireMonths
        )
    }
}
