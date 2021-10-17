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

    init(from decoder: Decoder) throws {
        self = try ClientConfigurationFlag(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

struct RawClientConfiguration: Codable, Equatable {

    let flags: [ClientConfigurationFlag]?
    let customKeyserverUrl: String?
    let keyManagerUrl: String?
    let disallowAttesterSearchForDomains: [String]?
    let enforceKeygenAlgo: String?
    let enforceKeygenExpireMonths: Int?

    init(
        flags: [ClientConfigurationFlag]? = nil,
        customKeyserverUrl: String? = nil,
        keyManagerUrl: String? = nil,
        disallowAttesterSearchForDomains: [String]? = nil,
        enforceKeygenAlgo: String? = nil,
        enforceKeygenExpireMonths: Int? = nil
    ) {
        self.flags = flags
        self.customKeyserverUrl = customKeyserverUrl
        self.keyManagerUrl = keyManagerUrl
        self.disallowAttesterSearchForDomains = disallowAttesterSearchForDomains
        self.enforceKeygenAlgo = enforceKeygenAlgo
        self.enforceKeygenExpireMonths = enforceKeygenExpireMonths
    }
}

// MARK: - Empty model
extension RawClientConfiguration {
    static var empty: RawClientConfiguration {
        return RawClientConfiguration(
            flags: [],
            customKeyserverUrl: nil,
            keyManagerUrl: nil,
            disallowAttesterSearchForDomains: nil,
            enforceKeygenAlgo: nil,
            enforceKeygenExpireMonths: nil
        )
    }
}

// MARK: - Map from realm model
extension RawClientConfiguration {
    init?(_ object: ClientConfigurationObject?) {
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
            flags: decodedFlags?.compactMap(ClientConfigurationFlag.init),
            customKeyserverUrl: unwrappedObject.customKeyserverUrl,
            keyManagerUrl: unwrappedObject.keyManagerUrl,
            disallowAttesterSearchForDomains: decodedDisallowAttesterSearchForDomains,
            enforceKeygenAlgo: unwrappedObject.enforceKeygenAlgo,
            enforceKeygenExpireMonths: unwrappedObject.enforceKeygenExpireMonths
        )
    }
}
