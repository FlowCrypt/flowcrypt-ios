//
//  KeyAlgo.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct KeyAlgo: Decodable {
    let algorithm: String
    let algorithmId: Int
    let bits: Int?
    let curve: String?
}
