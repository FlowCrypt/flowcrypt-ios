//
//  KeyDetails.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17/07/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import FlowCryptCommon

struct KeyDetails: Decodable {
    let `public`: String
    let `private`: String? // ony if this is prv
    let isFullyDecrypted: Bool? // only if this is prv
    let isFullyEncrypted: Bool? // only if this is prv
    let ids: [KeyId]
    let created: Int
    let users: [String]

    // TODO: -
    //    let algo: { // same as OpenPGP.key.AlgorithmInfo
    //        algorithm: string;
    //        algorithmId: number;
    //        bits?: number;
    //        curve?: string;
    //    };
}

extension KeyDetails: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.ids.first)
    }
}

extension KeyDetails: Equatable {
    static func == (lhs: KeyDetails, rhs: KeyDetails) -> Bool {
        lhs.ids == rhs.ids
    }
}
