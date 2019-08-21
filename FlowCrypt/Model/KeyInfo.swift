//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import RealmSwift

final class KeyInfo: Object {

    @objc dynamic var `private`: String = ""
    @objc dynamic var `public`: String = ""
    @objc dynamic var longid: String = ""
    @objc dynamic var passphrase: String = ""
    @objc dynamic var source: String = ""

    convenience init(_ keyDetails: KeyDetails, passphrase: String, source: String) {
        self.init()
        guard let privateKey = keyDetails.private else {
            assertionFailure("someone tries to pass a public key - that would be a programming error")
            // TODO: - Maybe better to show some alert or message to user without app crashing.
            // Or crash it with some logs to crashlytic or loger.
            _ = keyDetails.private! // crash the app
            return
        }
        self.private = privateKey
        self.public = keyDetails.public
        self.longid = keyDetails.ids[0].longid
        self.passphrase = passphrase
        self.source = source
    }

}

