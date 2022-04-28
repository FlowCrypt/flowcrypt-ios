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
import UIKit

enum KeyChainServiceError: Error {
    case storageEncryptionKeyFetchFailed(String)
}

extension KeyChainServiceError: CustomStringConvertible {
    var description: String {
        switch self {
        case .storageEncryptionKeyFetchFailed(let message):
            return message
        }
    }
}

struct KeyChainConfig: Codable {
    let dynamicPartIndex: String
}

/// keychain is used to generate and retrieve encryption key which is used to encrypt local DB
/// it does not contain any actual data or keys other than the db encryption key
/// index of the keychain entry is dynamic (set up once per app installation), set in user defaults
actor KeyChainService {

    private let logger = Logger.nested("KeyChain")
    private let keyByteLen = 64

    /// this dynamic keychainIndex ensures that we use a different keychain index
    ///   after deleting the app, because keychain entries survive app uninstall
    @MainActor private func getKeychainIndex() throws -> String {
        let fileName = "keychain-config"
        let fileManager = FilesManager()
//        let dynamicPartIndex = "indexSecureKeychainPrefix"
        if let file = try? fileManager.read(fileName: fileName),
            let config = try? file.decodeJson(as: KeyChainConfig.self) {
            return constructKeychainIndex(dynamicPart: config.dynamicPartIndex)
        }

        guard try !EncryptedStorage.isStorageExists else {
            throw KeyChainServiceError.storageEncryptionKeyFetchFailed("KeyChainService: failed to get encryption key prefix")
        }

        let newDynamicPart = try newRandomString()
        let config = KeyChainConfig(dynamicPartIndex: newDynamicPart)

        let file = FileItem(
            name: fileName,
            data: try config.toJsonData(),
            isEncrypted: false
        )
        _ = try fileManager.save(file: file, options: [.noFileProtection])
        return constructKeychainIndex(dynamicPart: newDynamicPart)
    }

    @MainActor private func newRandomString() throws -> String {
        logger.logInfo("newRandomString - generating new KeyChain index")
        guard let randomBytes = CoreHost().getSecureRandomByteNumberArray(12) else {
            throw AppErr.general("KeyChainService.newRandomString - randomBytes are nil")
        }
        return Data(randomBytes)
            .base64EncodedString()
            .replacingOccurrences(of: "[^A-Za-z0-9]+", with: "", options: [.regularExpression])
    }

    @MainActor private func constructKeychainIndex(dynamicPart: String) -> String {
        return dynamicPart + "-indexStorageEncryptionKey"
    }

    @MainActor private func generateAndSaveStorageEncryptionKey() throws {
        logger.logInfo("generateAndSaveStorageEncryptionKey")
        guard let randomBytes = CoreHost().getSecureRandomByteNumberArray(keyByteLen) else {
            throw AppErr.general("KeyChainService getSecureRandomByteNumberArray bytes are nil")
        }
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: try getKeychainIndex(),
            kSecValueData: Data(randomBytes)
        ]
        let addOsStatus = SecItemAdd(query as CFDictionary, nil)
        guard addOsStatus == noErr else {
            throw AppErr.general("KeyChainService SecItemAdd osStatus = \(addOsStatus), expected 'noErr'")
        }
    }

    @MainActor func getStorageEncryptionKey() throws -> Data {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: try getKeychainIndex(),
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
