//
//  ContactKeyObject.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 11/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift

final class ContactKeyObject: Object {
    @Persisted var key: String = ""

    @Persisted var lastSig: Date?
    @Persisted var lastChecked: Date?
    @Persisted var expiresOn: Date?
    @Persisted var longids: List<String>
    @Persisted var fingerprints: List<String>
    @Persisted var created: Date?
}
