//
//  KeychainKeyGenerator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol KeychainKeyGeneratorType {
    func generateKeyData() -> Data
}

struct KeychainKeyGenerator: KeychainKeyGeneratorType {
    private let provider: CoreHost
    
    init(provider: CoreHost = CoreHost()) {
        self.provider = provider
    }
    
    func generateKeyData() -> Data {
        guard let secureBytes = provider.getSecureRandomByteNumberArray(64) else {
            return generateKey()
        }
        
        return Data(secureBytes)
    }
    
    private func generateKey() -> Data {
        var key = Data(count: 64)
        _ = key.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 64, bytes)
        }
        return key
    }
}
