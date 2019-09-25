//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import RealmSwift

enum KeySource {
    case backup
    case generated

    var path: String {
        switch self {
            case .backup: return "backup"
            case .generated: return "generated"
        }
    }
}

final class KeyInfo: Object {

    @objc dynamic var `private`: String = ""
    @objc dynamic var `public`: String = ""
    @objc dynamic var longid: String = ""
    @objc dynamic var passphrase: String = ""
    @objc dynamic var source: String = ""

    convenience init(_ keyDetails: KeyDetails, passphrase: String, source: KeySource) throws {
        self.init()
        guard let privateKey = keyDetails.private else {
            assertionFailure("storing pubkey as private") // crash tests
            throw AppErr.value("storing pubkey as private")
        }
        guard keyDetails.isFullyEncrypted! else { // already checked private above, must be set, else crash
            assertionFailure("Will not store Private Key that is not fully encrypted") // crash tests
            throw AppErr.value("Will not store Private Key that is not fully encrypted")
        }
        self.private = privateKey
        self.public = keyDetails.public
        self.longid = keyDetails.ids[0].longid
        self.passphrase = passphrase
        self.source = source.path
    }

}

