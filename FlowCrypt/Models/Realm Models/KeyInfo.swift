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

final class KeyInfo: Object {
    var primaryLongid: String {
        allLongids[0]
    }

    @objc dynamic var `private`: String = ""
    @objc dynamic var `public`: String = ""

    let allFingerprints = List<String>()
    let allLongids = List<String>()

    @objc dynamic var primaryFingerprint = ""
    @objc dynamic var passphrase: String?
    @objc dynamic var source: String = ""
    @objc dynamic var user: UserObject!

    convenience init(_ keyDetails: KeyDetails, passphrase: String?, source: KeySource, user: UserObject) throws {
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

    override class func primaryKey() -> String? {
        "primaryFingerprint"
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
