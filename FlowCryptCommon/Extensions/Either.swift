//
//  Either.swift
//  FlowCryptCommon
//
//  Created by Anton Kharchevskyi on 24/04/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

public enum Either<A, B>{
    case left(A)
    case right(B)
}
