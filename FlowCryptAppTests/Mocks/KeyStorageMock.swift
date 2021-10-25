//
//  KeyStorageMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import Foundation

class KeyStorageMock: KeyStorageType {
    func addKeys(keyDetails: [KeyDetails], passPhrase: String?, source: KeySource, for email: String) {
    }

    func updateKeys(keyDetails: [KeyDetails], passPhrase: String?, source: KeySource, for email: String) {
    }

    var publicKeyResult: (() -> (String?))!
    func publicKey() -> String? {
        publicKeyResult()
    }

    var keysInfoResult: (() -> ([KeyInfo]))!
    func keysInfo() -> [KeyInfo] {
        keysInfoResult()
    }
}
