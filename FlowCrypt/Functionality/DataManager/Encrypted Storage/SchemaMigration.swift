//
//  SchemaMigration.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 08.12.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import RealmSwift

protocol RealmProperty {
    var propertyKey: String { get }
}

enum SchemaMigration {}

extension SchemaMigration {
    enum Properties {}
}

extension Object {
    subscript(property: RealmProperty) -> Any? {
        get {
            return self[property.propertyKey]
        }
        set {
            self[property.propertyKey] = newValue
        }
    }
}

extension SchemaMigration.Properties {
    enum User: String, RealmProperty {
        var propertyKey: String {
            rawValue
        }

        case email
        case isActive
        case name
        case imap
        case smtp
    }

    enum Folder: String, RealmProperty {
        var propertyKey: String {
            rawValue
        }

        case name
        case path
        case image
        case itemType
        case user
    }

    enum ClientConfiguration: String, RealmProperty {
        var propertyKey: String {
            rawValue
        }

        case flags
        case customKeyserverUrl
        case keyManagerUrl
        case disallowAttesterSearchForDomains
        case enforceKeygenAlgo
        case enforceKeygenExpireMonths
        case userEmail
        case user
    }

    enum PubKey: String, RealmProperty {
        var propertyKey: String {
            rawValue
        }

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
        var propertyKey: String {
            rawValue
        }

        case email
        case name
        case lastUsed
        case pubKeys
    }

    enum Session: String, RealmProperty {
        var propertyKey: String {
            rawValue
        }

        case hostname
        case port
        case username
        case password
        case oAuth2Token
        case connectionType
        case email
    }

    enum Keypair: String, RealmProperty {
        var propertyKey: String {
            rawValue
        }

        case primaryKey
        case primaryFingerprint
        case `private`
        case `public`
        case passphrase
        case source
        case user
        case allFingerprints
        case allLongids
    }
}
