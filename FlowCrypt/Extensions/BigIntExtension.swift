//
//  BigInt extensions.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 05/06/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

#warning("Should be checked with cryptographer before production")
// https://github.com/FlowCrypt/flowcrypt-ios/issues/238

func modPow<T: BinaryInteger>(n: T, e: T, m: T) -> T {
    guard e != 0 else {
        return 1
    }

    var res = T(1)
    var base = n % m
    var exp = e

    while true {
        if exp & 1 == 1 {
            res *= base
            res %= m
        }

        if exp == 1 {
            return res
        }

        exp /= 2
        base *= base
        base %= m
    }
}
