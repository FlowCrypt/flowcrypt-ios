//
//  EncryptedStorageProtocols.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

protocol KeyStorageType {
    func addKeys(keyDetails: [KeyDetails], source: KeySource, for email: String)
    func updateKeys(keyDetails: [KeyDetails], source: KeySource, for email: String)
    func publicKey() -> String?
    func keysInfo() -> [KeyInfo]
}
