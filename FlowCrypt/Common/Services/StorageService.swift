//
//  StorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

protocol StorageServiceType {
    func store(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
}

struct StorageService: StorageServiceType {
    var storage: Realm {
        return try! Realm()
    }

    func store(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
        try! storage.write {
            for k in keyDetails {
                storage.add(try! KeyInfo(k, passphrase: passPhrase, source: source))
            }
        }
    }
}
