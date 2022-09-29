//
//  KeyAndPassPhraseStorage.swift
//  FlowCrypt
//
//  Created by Tom on 2022-05-07.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import FlowCryptCommon

protocol KeyAndPassPhraseStorageType {
    func getKeypairsWithPassPhrases(email: String) async throws -> [Keypair]
}

final class KeyAndPassPhraseStorage: KeyAndPassPhraseStorageType {

    let encryptedStorage: EncryptedStorageType
    let combinedPassPhraseStorage: CombinedPassPhraseStorageType

    init(
        encryptedStorage: EncryptedStorageType,
        combinedPassPhraseStorage: CombinedPassPhraseStorageType
    ) {
        self.encryptedStorage = encryptedStorage
        self.combinedPassPhraseStorage = combinedPassPhraseStorage
    }

    func getKeypairsWithPassPhrases(email: String) async throws -> [Keypair] {
        let storedPassPhrases = try await combinedPassPhraseStorage.getPassPhrases(for: email)
        var keypairs = try encryptedStorage.getKeypairs(by: email)
        for i in keypairs.indices {
            keypairs[i].passphrase = keypairs[i].passphrase ?? storedPassPhrases
                .filter { $0.value.isNotEmpty }
                .first(where: { $0.primaryFingerprintOfAssociatedKey == keypairs[i].primaryFingerprint })?
                .value
        }
        return keypairs
    }
}
