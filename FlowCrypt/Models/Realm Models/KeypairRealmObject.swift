//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import CryptoKit
import RealmSwift

enum KeySource: String {
    case backup
    case generated
    case imported
    case ekm
}

final class KeypairRealmObject: Object {
    @Persisted(primaryKey: true) var primaryKey: String // swiftlint:disable:this attributes
    @Persisted var primaryFingerprint: String
    @Persisted var `private`: String
    @Persisted var `public`: String
    @Persisted var passphrase: String?
    @Persisted var source: String
    @Persisted var lastModified: Int = 0
    @Persisted var user: UserRealmObject?
    @Persisted var allFingerprints: List<String>
    @Persisted var allLongids: List<String>
    @Persisted var isRevoked = false

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

        let keypair = try Keypair(keyDetails, passPhrase: passphrase, source: source.rawValue)

        self.private = keypair.private
        self.public = keypair.public
        self.allFingerprints.append(objectsIn: keypair.allFingerprints)
        self.allLongids.append(objectsIn: keypair.allLongids)
        self.primaryKey = keypair.primaryFingerprint + user.email
        self.primaryFingerprint = keypair.primaryFingerprint
        self.passphrase = passphrase
        self.source = source.rawValue
        self.lastModified = keypair.lastModified
        self.user = user
        self.isRevoked = keypair.isRevoked
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
