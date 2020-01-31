//
//  KeyChainService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Security

// keychain is used to generate and retrieve encryption key which is used to encrypt local DB
// it does not contain any actual data or keys other than the db encryption key

protocol KeyChainServiceType {
    func getStorageEncryptionKey() -> Data
}

struct KeyChainService: KeyChainServiceType {
    private let encryptionKeyTag: String
    private let keyByteLen = 64

    init() {
        // the prefix ensures that we use a different keychain index after deleting the app
        // because keychain entries survive app uninstall
        encryptionKeyTag = "\(LocalStorage().secureKeychainPrefix())-flowcrypt-realm-encryption-key"
    }

    private func generateAndSaveStorageEncryptionKey() {
        print("KeyChainService->generateAndSaveStorageEncryptionKey")
        guard let randomBytes = CoreHost().getSecureRandomByteNumberArray(keyByteLen) else {
            fatalError("KeyChainServiceType generateAndSaveStorageEncryptionKey getSecureRandomByteNumberArray bytes are nil")
        }
        let key = Data(randomBytes)
        let query: [CFString : Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: encryptionKeyTag,
            kSecValueData: key
        ]
        let addOsStatus = SecItemAdd(query as CFDictionary, nil)
        guard addOsStatus == noErr else {
            fatalError("KeyChainServiceType generateAndSaveStorageEncryptionKey SecItemAdd osStatus = \(addOsStatus), expected 'noErr'")
        }
    }

    func getStorageEncryptionKey() -> Data {
        let query: [CFString : Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: encryptionKeyTag,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var keyFromKeychain: AnyObject? = nil
        let findOsStatus = SecItemCopyMatching(query as CFDictionary, &keyFromKeychain)
        guard findOsStatus != errSecItemNotFound else {
            generateAndSaveStorageEncryptionKey() // saves new key to storage
            return getStorageEncryptionKey() // retries search
        }
        guard findOsStatus == noErr else {
            fatalError("KeyChainServiceType getStorageEncryptionKey SecItemCopyMatching status = \(findOsStatus), expected 'noErr'")
        }
        guard let validKey = keyFromKeychain as? Data else {
            fatalError("KeyChainServiceType getStorageEncryptionKey keyFromKeychain not usable as Data. Is nil?: \(keyFromKeychain == nil)")
        }
        guard validKey.count == keyByteLen else {
            fatalError("KeyChainServiceType getStorageEncryptionKey validKey.count != \(keyByteLen), instead is \(validKey.count)")
        }
        return validKey
    }
}
