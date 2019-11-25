//
//  StorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Security
import RealmSwift

protocol StorageServiceType {
    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
    func publicKey() -> String?
    func keys() -> Results<KeyInfo>
}

protocol EncryptedStorageType {
    func clear(for email: String)
}

struct StorageService: StorageServiceType {
    let keychainHelper: KeyChainServiceType

    private var storage: (String) -> (Realm?) {
        return { email in
            guard let data = self.keychainHelper.getEncryptedKey(for: email) else {
                assertionFailure("Can't get data from keychain")
                return nil
            }
            // TODO: Anton -
            return try! Realm(configuration: Realm.Configuration(encryptionKey: data))

//            guard let realm = try? Realm(configuration: Realm.Configuration(encryptionKey: data)) else {
//                assertionFailure("Can't get Realm instance")
//                return nil
//            }
//            return realm
        }

    }

    private var email: String {
         // TODO: Anton -
        return DataManager.shared.email!
    }

    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
        try! storage(email).write {
            for k in keyDetails {
                storage.add(try! KeyInfo(k, passphrase: passPhrase, source: source))
            }
        }
    }

    func publicKey() -> String? {
        return storage(email).objects(KeyInfo.self)
            .map { $0.public }
            .first 
    }

    func keys() -> Results<KeyInfo> {
        storage(email).objects(KeyInfo.self)
    }



}

extension StorageService: EncryptedStorageType {
    func clear(for email: String) {
        guard let realm = storage(email) else { assertionFailure("Realm should exist"); return }
        try? realm.write {
            realm.deleteAll()
        }
    }
}

protocol KeyChainServiceType {
    func saveEncryptedKey(for email: String) -> KeyChainStatus
    func getEncryptedKey(for email: String) -> Data?

}

enum KeyChainStatus {
    case success, noData

    init(_ osStatus: OSStatus) {
        if osStatus == noErr {
            self = .success
        } else {
            self = .noData
        }
    }
}

struct KeyChainService: KeyChainServiceType {
    private let keyTag = "EncryptedKey"
    private let keyGenerator: KeychainKeyGeneratorType

    func saveEncryptedKey(for email: String) -> KeyChainStatus {
        let key = keyGenerator.generateKeyData()
        let tag = generateTag(for: email)

        let query: [CFString : Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tag,
            kSecValueData: key
        ]

        SecItemDelete(query as CFDictionary)
        let osStatus = SecItemAdd(query as CFDictionary, nil)
        return KeyChainStatus(osStatus)
    }

    func getEncryptedKey(for email: String) -> Data? {
        let tag = generateTag(for: email)

        let query: [CFString : Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tag,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject? = nil

        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == noErr, let data = dataTypeRef as? Data else {
            assertionFailure()
            return nil
        }
        return data
    }

    private func generateTag(for email: String) -> String {
        keyTag + email
    }
}

protocol KeychainKeyGeneratorType {
    func generateKeyData() -> Data
}

struct KeychainKeyGenerator: KeychainKeyGeneratorType {
    func generateKeyData() -> Data {
        var key = Data(count: 64)
        _ = key.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 64, bytes)
        }
        return key
    }
}
