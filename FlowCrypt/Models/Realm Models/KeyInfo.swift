//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import RealmSwift

enum KeySource: String {
    case backup
    case generated
    case imported
}

enum KeyInfoError: Error {
    case missedPrivateKey(String)
    case notEncrypted(String)
    case missedKeyIds
}

final class KeyInfo: Object {
    var primaryFingerprint: String? {
        allFingerprints.first
    }
    var primaryLongid: String {
        // explicitly force unwrap
        allLongids.first!
    }

    @objc dynamic var `private`: String = ""
    @objc dynamic var `public`: String = ""

    let allFingerprints = List<String>()
    let allLongids = List<String>()

    @objc dynamic var source: String = ""
    @objc dynamic var user: UserObject!

    convenience init(_ keyDetails: KeyDetails, source: KeySource, user: UserObject) throws {
        self.init()

        guard let privateKey = keyDetails.private else {
            assertionFailure("storing pubkey as private") // crash tests
            throw KeyInfoError.missedPrivateKey("storing pubkey as private")
        }
        guard keyDetails.isFullyEncrypted! else { // already checked private above, must be set, else crash
            assertionFailure("Will not store Private Key that is not fully encrypted") // crash tests
            throw KeyInfoError.notEncrypted("Will not store Private Key that is not fully encrypted")
        }
        guard keyDetails.ids.isNotEmpty else {
            assertionFailure("KeyDetails KeyIds should not be empty")
            throw KeyInfoError.missedKeyIds
        }

        self.`private` = privateKey
        self.`public` = keyDetails.public
        self.allFingerprints.append(objectsIn: keyDetails.ids.map(\.fingerprint))
        self.allLongids.append(objectsIn: keyDetails.ids.map(\.longid))
        self.source = source.rawValue
        self.user = user
    }

    override class func primaryKey() -> String? {
        "private"
    }

    override var description: String {
        "account = \(user?.email ?? "N/A") ####### longid = \(primaryLongid)"
    }
}

extension KeyInfo {
    /// associated user email
    var account: String {
        user.email
    }
}
