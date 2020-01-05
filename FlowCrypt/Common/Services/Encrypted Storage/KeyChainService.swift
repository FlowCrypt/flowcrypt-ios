//
//  KeyChainService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Security

protocol KeyChainServiceType {
    func generateAndSaveStorageEncryptionKey() -> KeyChainStatus
    func getStorageEncryptionKey() -> Data?

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
    private let tag = "flowcrypt-realm-encryption-key"

    init() { }

    func generateAndSaveStorageEncryptionKey() -> KeyChainStatus {
        let key = Data(CoreHost().getSecureRandomByteNumberArray(64)!) // ok to crash app when missing, should be extremely rare

        let query: [CFString : Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tag,
            kSecValueData: key
        ]

        SecItemDelete(query as CFDictionary)
        let osStatus = SecItemAdd(query as CFDictionary, nil)
        return KeyChainStatus(osStatus)
    }

    func getStorageEncryptionKey() -> Data? {
        let query: [CFString : Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tag,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject? = nil

        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == noErr, let data = dataTypeRef as? Data else {
            return nil
        } 
        return data
    }
}
