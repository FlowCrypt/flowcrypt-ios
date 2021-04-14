//
//  KeyAlgoObject.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

final class KeyAlgoObject: Object {
    @objc dynamic var algorithm: String = ""
    @objc dynamic var algorithmId: Int = 0
    @objc dynamic var bits: Int = 0
    @objc dynamic var curve: String = ""

    convenience init(algo: KeyAlgo) {
        self.init()
        self.algorithm = algo.algorithm
        self.algorithmId = algo.algorithmId
        self.bits = algo.bits ?? 0
        self.curve = algo.curve ?? ""
    }
}

extension KeyAlgo {
    init(algoObject: KeyAlgoObject) {
        self.init(
            algorithm: algoObject.algorithm,
            algorithmId: algoObject.algorithmId,
            bits: algoObject.bits,
            curve: algoObject.curve
        )
    }
}
