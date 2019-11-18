//
//  BackupService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol BackupServiceType {
    func match(keys fetchedEncryptedPrvs: [KeyDetails], with passPhrase: String) -> [KeyDetails]
}

struct BackupService: BackupServiceType {
    let core: Core

    func match(keys fetchedEncryptedPrvs: [KeyDetails], with passPhrase: String) -> [KeyDetails] {
        return fetchedEncryptedPrvs
            .compactMap { key -> KeyDetails? in
                guard let privateKey = key.private,
                    let decrypted = try? self.core.decryptKey(armoredPrv: privateKey, passphrase: passPhrase),
                    decrypted.decryptedKey != nil
                else { return nil }
                return key
            }
    }
}

