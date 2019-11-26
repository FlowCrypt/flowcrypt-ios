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

    init(
        keyGenerator: KeychainKeyGeneratorType = KeychainKeyGenerator()
    ) {
        self.keyGenerator = keyGenerator
    }

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
