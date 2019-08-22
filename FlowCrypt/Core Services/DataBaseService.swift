//
//  DataBaseService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/22/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises
import RealmSwift

enum DataBaseError {
    case failedToSave
}

protocol DataBaseService {
    func save(message data: Data, isEmail: Bool) -> Promise<CoreRes.ParseDecryptMsg>
}

struct RealmDataBaseService: DataBaseService {
    static let shared = RealmDataBaseService()

    func save(message data: Data, isEmail: Bool) -> Promise<CoreRes.ParseDecryptMsg> {
        return Promise { resolve, reject in
            let realm = try Realm()
            let keys = PrvKeyInfo.from(realm: realm.objects(KeyInfo.self))
            do {
                let decrypted = try Core.parseDecryptMsg(
                    encrypted: data,
                    keys: keys,
                    msgPwd: nil,
                    isEmail: isEmail
                )
                resolve(decrypted)
            } catch let error {
                reject(error)
            }
        }

    }
}
