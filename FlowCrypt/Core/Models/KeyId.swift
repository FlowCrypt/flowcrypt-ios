//
//  KeyId.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17/07/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct KeyId: Decodable, Equatable, Hashable {
    let shortid: String
    let longid: String
    let fingerprint: String
    let keywords: String
}
