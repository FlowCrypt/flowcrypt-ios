//
//  CoreError.swift
//  FlowCrypt
//
//  Created by Evgenii Kyivskyi on 11/7/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    

import Foundation

enum CoreError: LocalizedError, Equatable {
    case exception(String)
    case notReady(String)
    case format(String)
    case keyMismatch(String)
    case noMDC(String)
    case badMDC(String)
    case needPassphrase(String)
    case wrongPassphrase(String)
    // wrong value passed into a function
    case value(String)

    init(coreError: CoreRes.Error) {
        switch coreError.error.type {
        case "format": self = .format(coreError.error.message)
        case "key_mismatch": self = .keyMismatch(coreError.error.message)
        case "no_mdc": self = .noMDC(coreError.error.message)
        case "bad_mdc": self = .badMDC(coreError.error.message)
        case "need_passphrase": self = .needPassphrase(coreError.error.message)
        case "wrong_passphrase": self = .wrongPassphrase(coreError.error.message)
        default: self = .exception(coreError.error.message + "\n" + (coreError.error.stack ?? "no stack"))
        }
    }

    var errorDescription: String? {
        switch self {
        case .exception(let message),
                .notReady(let message),
                .format(let message),
                .keyMismatch(let message),
                .noMDC(let message),
                .badMDC(let message),
                .needPassphrase(let message),
                .wrongPassphrase(let message),
                .value(let message):
            return message
        }
    }
}
