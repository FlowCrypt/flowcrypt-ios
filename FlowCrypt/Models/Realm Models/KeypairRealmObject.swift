//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift
import CryptoKit

enum KeySource: String {
    case backup
    case generated
    case imported
    case ekm
}

final class KeypairRealmObject: Object {
    @Persisted(primaryKey: true) var primaryKey: String
    @Persisted var primaryFingerprint: String
    @Persisted var `private`: String
    @Persisted var `public`: String
    @Persisted var passphrase: String?
    @Persisted var source: String
    @Persisted var lastModified: Int = 0
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

extension KeypairRealmObject {
    convenience init(_ keyDetails: KeyDetails, passphrase: String?, source: KeySource, user: UserRealmObject) throws {
        self.init()

        guard let privateKey = keyDetails.private, let isFullyEncrypted = keyDetails.isFullyEncrypted else {
            throw KeypairError.missingPrivateKey("storing pubkey as private")
        }
        guard isFullyEncrypted else {
            throw KeypairError.notEncrypted("Will not store Private Key that is not fully encrypted")
        }
        guard keyDetails.ids.isNotEmpty else {
            throw KeypairError.missingKeyIds
        }
        guard let primaryFingerprint = keyDetails.ids.first?.fingerprint else {
            throw KeypairError.missingPrimaryFingerprint
        }

        self.`private` = privateKey
        self.`public` = keyDetails.public
        self.allFingerprints.append(objectsIn: keyDetails.ids.map(\.fingerprint))
        self.allLongids.append(objectsIn: keyDetails.ids.map(\.longid))
        self.primaryKey = primaryFingerprint + user.email
        self.primaryFingerprint = primaryFingerprint
        self.passphrase = passphrase
        self.source = source.rawValue
        self.lastModified = keyDetails.lastModified ?? 0
        self.user = user
    }
}

extension KeypairRealmObject {
    /// associated user email
    var account: String {
        guard let email = user?.email else { fatalError() }
        return email
    }
}

extension KeypairRealmObject {
    static func createPrimaryKey(primaryFingerprint: String, email: String) -> String {
        var hash = SHA256()
        hash.update(data: primaryFingerprint.data())
        hash.update(data: Data(count: 1)) // null byte
        hash.update(data: email.data())
        return hash.finalize()
            .compactMap { String(format: "%02x", $0) }.joined()
    }
}
