//
//  SchemaMigration.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 08.12.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import RealmSwift

protocol RealmProperty {
    var rawValue: String { get }
}

enum SchemaMigration {
    struct Properties {}
}

extension Object {
    subscript(property: RealmProperty) -> Any? {
        get {
            return self[property.rawValue]
        }
        set {
            self[property.rawValue] = newValue
        }
    }
}

extension SchemaMigration.Properties {
    enum User: String, RealmProperty {
        case email
        case isActive
        case name
        case imap
        case smtp
    }

    enum Folder: String, RealmProperty {
        case name
        case path
        case image
        case itemType
        case user
    }

    enum ClientConfiguration: String, RealmProperty {
        case flags
        case customKeyserverUrl
        case keyManagerUrl
        case disallowAttesterSearchForDomains
        case allowAttesterSearchOnlyForDomains
        case enforceKeygenAlgo
        case enforceKeygenExpireMonths
        case userEmail
        case user
    }

    enum PubKey: String, RealmProperty {
        case primaryFingerprint
        case armored
        case lastSig
        case lastChecked
        case expiresOn
        case longids
        case fingerprints
        case created
    }

    enum Recipient: String, RealmProperty {
        case email
        case name
        case lastUsed
        case pubKeys
    }

    enum Session: String, RealmProperty {
        case hostname
        case port
        case username
        case password
        case oAuth2Token
        case connectionType
        case email
    }

    enum Keypair: String, RealmProperty {
        case primaryKey
        case primaryFingerprint
        case `private`
        case `public`
        case passphrase
        case source
        case user
        case allFingerprints
        case allLongids
        case lastModified
    }
}
