//
//  EncryptedStorageProtocols.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol KeyStorageType {
    func addKeys(keyDetails: [KeyDetails], source: KeySource)
    func updateKeys(keyDetails: [KeyDetails], source: KeySource)
    func publicKey() -> String?
    func keysInfo() -> [KeyInfo]
}

protocol EncryptedPassPhraseStorage {
    func addPassPhrase(object: PassPhraseObject)
    func updatePassPhrase(object: PassPhraseObject)
    func getPassPhrases() -> [PassPhraseObject]
    func removePassPhrase(object: PassPhraseObject)
    func keysInfo() -> [KeyInfo]
}
