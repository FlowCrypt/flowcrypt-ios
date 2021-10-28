//
//  KeyChainService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation
import Security

// keychain is used to generate and retrieve encryption key which is used to encrypt local DB
// it does not contain any actual data or keys other than the db encryption key

protocol KeyChainServiceType {
    func getStorageEncryptionKey() throws -> Data
}

struct KeyChainService: KeyChainServiceType {
    private static var logger = Logger.nested(in: Self.self, with: "Keychain")

    // the prefix ensures that we use a different keychain index after deleting the app
    // because keychain entries survive app uninstall
    private static var keychainIndex: String = {
        // todo - verify if this is indeed atomic (because static) or if there can be a race condition
        let prefixStorageIndex = "indexSecureKeychainPrefix"
        let storageEncryptionKeyIndexSuffix = "-indexStorageEncryptionKey"
        if let storedPrefix = UserDefaults.standard.string(forKey: prefixStorageIndex) {
            return storedPrefix + storageEncryptionKeyIndexSuffix
        }
        guard let randomBytes = CoreHost().getSecureRandomByteNumberArray(12) else {
            fatalError("could not get secureKeychainPrefix random bytes")
        }
        let prefix = Data(randomBytes)
            .base64EncodedString()
            .replacingOccurrences(of: "[^A-Za-z0-9]+", with: "", options: [.regularExpression])

        logger.logInfo("LocalStorage.secureKeychainPrefix generating new prefix")
        UserDefaults.standard.set(prefix, forKey: prefixStorageIndex)
        return prefix + storageEncryptionKeyIndexSuffix
    }()

    private let keyByteLen = 64

    private func generateAndSaveStorageEncryptionKey() throws {
        Self.logger.logInfo("generateAndSaveStorageEncryptionKey")

        guard let randomBytes = CoreHost().getSecureRandomByteNumberArray(keyByteLen) else {
            let message = "KeyChainService getSecureRandomByteNumberArray bytes are nil"
            throw AppErr.general(message)
        }

        let key = Data(randomBytes)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: KeyChainService.keychainIndex,
            kSecValueData: key
        ]
        let addOsStatus = SecItemAdd(query as CFDictionary, nil)
        guard addOsStatus == noErr else {
            let message = "KeyChainService SecItemAdd osStatus = \(addOsStatus), expected 'noErr'"
            throw AppErr.general(message)
        }
    }

    func getStorageEncryptionKey() throws -> Data {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: KeyChainService.keychainIndex,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var keyFromKeychain: AnyObject?
        let findOsStatus = SecItemCopyMatching(query as CFDictionary, &keyFromKeychain)
        guard findOsStatus != errSecItemNotFound else {
            try generateAndSaveStorageEncryptionKey() // saves new key to storage
            return try getStorageEncryptionKey() // retries search
        }

        guard findOsStatus == noErr else {
            let message = "KeyChainService SecItemCopyMatching status = \(findOsStatus), expected 'noErr'"
            throw AppErr.general(message)
        }

        guard let validKey = keyFromKeychain as? Data else {
            let message = "KeyChainService keyFromKeychain not usable as Data. Is nil?: \(keyFromKeychain == nil)"
            throw AppErr.general(message)
        }

        guard validKey.count == keyByteLen else {
            let message = "KeyChainService validKey.count != \(keyByteLen), instead is \(validKey.count)"
            throw AppErr.general(message)
        }

        return validKey
    }
}
