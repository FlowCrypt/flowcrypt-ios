//
//  PassPhraseInfo.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

/// PassPhrase object to store in Realm
final class PassPhraseObject: Object {
    @objc dynamic var longid: String = ""
    @objc dynamic var value: String = ""

    convenience init(
        longid: String = "",
        value: String = ""
    ) {
        self.init()
        self.value = value
        self.longid = longid
    }
}

// MARK: - Convenience
extension PassPhraseObject {
    convenience init(_ passPhrase: PassPhrase) {
        self.init(longid: passPhrase.longid, value: passPhrase.value)
    }
}

extension PassPhrase {
    init(object: PassPhraseObject) {
        self.value = object.value
        self.longid = object.longid
        self.date = nil
    }
}
