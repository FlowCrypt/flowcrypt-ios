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
    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
    func publicKey() -> String?
    func keys() -> Results<KeyInfo>
}

struct StorageService: StorageServiceType {
    var storage: Realm {
        return try! Realm()
    }

    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
        try! storage.write {
            for k in keyDetails {
                storage.add(try! KeyInfo(k, passphrase: passPhrase, source: source))
            }
        }
    }

    func publicKey() -> String? {
        return storage.objects(KeyInfo.self)
            .map { $0.public }
            .first 
    }

    func keys() -> Results<KeyInfo> {
        storage.objects(KeyInfo.self)
    }
}
