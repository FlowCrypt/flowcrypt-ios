//
//  PassPhraseInfo.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift

/// PassPhrase object to store in Realm
final class PassPhraseObject: Object {
    @objc dynamic var value: String = ""
    let allFingerprints = List<String>()

    convenience init(
        value: String = "",
        fingerprints: [String]
    ) {
        self.init()
        self.value = value
        self.allFingerprints.append(objectsIn: fingerprints)
    }

    override class func primaryKey() -> String? {
        "value"
    }
}

// MARK: - Convenience
extension PassPhraseObject {
    var primaryFingerprint: String {
        allFingerprints[0]
    }

    convenience init(_ passPhrase: PassPhrase) {
        self.init(value: passPhrase.value, fingerprints: passPhrase.fingerprints)
    }
}

extension PassPhrase {
    init(object: PassPhraseObject) {
        self.value = object.value
        self.fingerprints = Array(object.allFingerprints)
        self.date = nil
    }
}
