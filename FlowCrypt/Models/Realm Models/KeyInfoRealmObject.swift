//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

enum KeySource: String {
    case backup
    case generated
    case imported
    case ekm
}

enum KeyInfoError: Error {
    case missingPrivateKey(String)
    case notEncrypted(String)
    case missingKeyIds
    case missingPrimaryFingerprint
}

final class KeyInfoRealmObject: Object {
    @Persisted(primaryKey: true) var primaryFingerprint = ""
    @Persisted var `private`: String = ""
    @Persisted var `public`: String = ""
    @Persisted var passphrase: String?
    @Persisted var source: String = ""
    @Persisted var user: UserRealmObject?
    @Persisted var allFingerprints: List<String>
    @Persisted var allLongids: List<String>

    var primaryLongid: String {
        allLongids[0]
    }

    override var description: String {
        "account = \(user?.email ?? "N/A") ####### longid = \(primaryLongid)"
    }
}

extension KeyInfoRealmObject {
    convenience init(_ keyDetails: KeyDetails, passphrase: String?, source: KeySource, user: UserRealmObject) throws {
        self.init()

        guard let privateKey = keyDetails.private else {
            throw KeyInfoError.missingPrivateKey("storing pubkey as private")
        }
        guard keyDetails.isFullyEncrypted! else {
            throw KeyInfoError.notEncrypted("Will not store Private Key that is not fully encrypted")
        }
        guard keyDetails.ids.isNotEmpty else {
            throw KeyInfoError.missingKeyIds
        }

        self.`private` = privateKey
        self.`public` = keyDetails.public
        self.allFingerprints.append(objectsIn: keyDetails.ids.map(\.fingerprint))
        self.allLongids.append(objectsIn: keyDetails.ids.map(\.longid))

        guard let primaryFingerprint = self.allFingerprints.first else {
            throw KeyInfoError.missingPrimaryFingerprint
        }

        self.primaryFingerprint = primaryFingerprint
        self.passphrase = passphrase
        self.source = source.rawValue
        self.user = user
    }
}

extension KeyInfoRealmObject {
    /// associated user email
    var account: String? {
        user?.email
    }
}
