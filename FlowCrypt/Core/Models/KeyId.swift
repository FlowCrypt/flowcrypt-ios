//
//  KeyId.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17/07/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct KeyId: Decodable {
    let longid: String
    let fingerprint: String

    init(longid: String, fingerprint: String) {
        self.longid = longid
        self.fingerprint = fingerprint
    }
}

extension KeyId: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(fingerprint)
    }
}

extension KeyId: Equatable {
    static func == (lhs: KeyId, rhs: KeyId) -> Bool {
        lhs.fingerprint == rhs.fingerprint
    }
}
