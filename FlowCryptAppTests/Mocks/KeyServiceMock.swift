//
//  KeyServiceMock.swift
//  FlowCryptAppTests
//
//  Created by Ioan Moldovan on 04.28.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import RealmSwift

final class KeyServiceMock: KeyServiceType {
    var getPrvKeyInfoResult: [PrvKeyInfo] = []
    func getPrvKeyInfo(email: String) async throws -> [PrvKeyInfo] {
        getPrvKeyInfoResult
    }

    var getSigningKeyResult: PrvKeyInfo?
    func getSigningKey(email: String) async throws -> PrvKeyInfo? {
        getSigningKeyResult
    }

    var getKeyPairResult: Keypair?
    func getKeyPair(from email: String) async throws -> Keypair? {
        getKeyPairResult
    }
}
