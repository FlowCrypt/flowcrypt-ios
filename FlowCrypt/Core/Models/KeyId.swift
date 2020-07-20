//
//  KeyId.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17/07/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct KeyId: Decodable {
    let shortid: String
    let longid: String
    let fingerprint: String
    let keywords: String
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
