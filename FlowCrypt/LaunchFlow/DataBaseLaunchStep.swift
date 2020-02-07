//
//  DataBaseLaunchStep.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct DataBaseLaunchStep: FlowStepHandler {
    func execute(with launchContext: LaunchContext, completion: @escaping (Bool) -> Void) -> Bool {
        /*
         // Get the encryptionKey
         var realmKey = Keychain.realmKey
         if realmKey == nil {
             var key = Data(count: 64)

             key.withUnsafeMutableBytes { (bytes) -> Void in
                 _ = SecRandomCopyBytes(kSecRandomDefault, 64, bytes)
             }
             realmKey = key
             Keychain.realmKey = realmKey
         }


         // Check if the user has the unencrypted Realm
         let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
         let fileManager = FileManager.default
         let unencryptedRealmPath = "\(documentDirectory)/default.realm"
         let encryptedPath = "\(documentDirectory)/default_new.realm"
         let isUnencryptedRealmExsist = fileManager.fileExists(atPath: unencryptedRealmPath)
         let isEncryptedRealmExsist = fileManager.fileExists(atPath: encryptedPath)


         if isUnencryptedRealmExsist && !isEncryptedRealmExsist {
             let unencryptedRealm = try! Realm(configuration: Realm.Configuration(schemaVersion: 7))
             // if the user has unencrypted Realm write a copy to new path
             try? unencryptedRealm.writeCopy(toFile: URL(fileURLWithPath: encryptedPath), encryptionKey: realmKey)
         }

         // read from the new encrypted Realm path
         let configuration = Realm.Configuration(fileURL: URL(fileURLWithPath: encryptedPath), encryptionKey: realmKey, schemaVersion: 7, migrationBlock: { migration, oldSchemaVersion in })

         return try! Realm(configuration: configuration)
         */

        return true
    }
}
