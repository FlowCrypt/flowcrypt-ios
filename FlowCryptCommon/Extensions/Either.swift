//
//  Either.swift
//  FlowCryptCommon
//
//  Created by Anton Kharchevskyi on 24/04/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

public enum Either<A, B> {
    case left(A)
    case right(B)
}
