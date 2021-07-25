//
//  KeyStorageMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
@testable import FlowCrypt

class KeyStorageMock: KeyStorageType {
    func addKeys(keyDetails: [KeyDetails], source: KeySource, for email: String) {
        
    }
    
    func updateKeys(keyDetails: [KeyDetails], source: KeySource, for email: String) {
        
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
