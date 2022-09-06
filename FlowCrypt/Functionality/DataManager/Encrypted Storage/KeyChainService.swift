//
//  KeyChainService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.11.2019
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation
import Security
import UIKit

/// keychain is used to generate and retrieve encryption key which is used to encrypt local DB
/// it does not contain any actual data or keys other than the db encryption key
/// index of the keychain entry is dynamic (set up once per app installation), set in user defaults
actor KeyChainService {

    private let logger = Logger.nested("KeyChain")
    private let keyByteLen = 64

    private enum Constants {
        static let legacyKeychainIndexPrefixInUserDefaults = "indexSecureKeychainPrefix"
        static let keychainPropertyKey = "app-storage-encryption-key"
    }

    @MainActor var storageEncryptionKey: Data {
        get throws {
            if let key = try fetchEncryptionKey() {
                return key
            }

            // TODO: Should be removed after all users migrated to new keychain
            if let legacyKey = try fetchLegacyEncryptionKey() {
                try saveStorageEncryptionKey(data: legacyKey)
                removeLegacyEncryptionKey()
                return legacyKey
            }

            return try generateAndSaveStorageEncryptionKey()
        }
    }

    @MainActor private func fetchLegacyEncryptionKey() throws -> Data? {
        let prefixKey = Constants.legacyKeychainIndexPrefixInUserDefaults

        guard let storedDynamicPart = UserDefaults.standard.string(forKey: prefixKey)
        else { return nil }

        let storageKey = storedDynamicPart + "-indexStorageEncryptionKey"

        guard let encryptionKey = try fetchEncryptionKey(property: storageKey) else {
            if try EncryptedStorage.doesStorageFileExist {
                throw AppErr.general(
                    "KeyChainService: got legacy dynamic prefix from user defaults but could not find entry in key chain based on it"
                )
            }
            return nil
        }

        return encryptionKey
    }

    @MainActor private func removeLegacyEncryptionKey() {
        UserDefaults.standard.removeObject(
            forKey: Constants.legacyKeychainIndexPrefixInUserDefaults
        )
    }

    @MainActor private func generateAndSaveStorageEncryptionKey() throws -> Data {
        logger.logInfo("generate storage encryption key")

        guard let randomBytes = CoreHost().getSecureRandomByteNumberArray(keyByteLen) else {
            throw AppErr.general("KeyChainService getSecureRandomByteNumberArray bytes are nil")
        }

        let keyData = Data(randomBytes)
        try saveStorageEncryptionKey(data: keyData)

        return keyData
    }

    @MainActor private func saveStorageEncryptionKey(data: Data) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: Constants.keychainPropertyKey,
            kSecValueData: data
        ]
        let addOsStatus = SecItemAdd(query as CFDictionary, nil)
        guard addOsStatus == noErr else {
            throw AppErr.general("KeyChainService SecItemAdd osStatus = \(addOsStatus), expected 'noErr'")
        }
    }

    @MainActor private func fetchEncryptionKey(
        property: String = Constants.keychainPropertyKey
    ) throws -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: property,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var keyFromKeychain: AnyObject?
        let findOsStatus = SecItemCopyMatching(query as CFDictionary, &keyFromKeychain)

        guard findOsStatus != errSecItemNotFound else {
            return nil
        }

        guard findOsStatus == noErr else {
            throw AppErr.general("KeyChainService SecItemCopyMatching status = \(findOsStatus), expected 'noErr'")
        }

        guard let validKey = keyFromKeychain as? Data else {
            throw AppErr.general("KeyChainService keyFromKeychain not usable as Data. Is nil?: \(keyFromKeychain == nil)")
        }

        guard validKey.count == keyByteLen else {
            throw AppErr.general("KeyChainService validKey.count != \(keyByteLen), instead is \(validKey.count)")
        }

        return validKey
    }
}
