//
//  Localization.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 08.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

@inline(__always) private func localize(_ key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

@inline(__always) private func LocalizedString(_ key: String) -> String {
    return localize(key)
}

public extension String {
    var localized: String {
        return LocalizedString(self)
    }

    @inline(__always) func localizeWithArguments(_ arguments: String...) -> String {
        let format = localize(self)
        return String(format: format, arguments: arguments)
    }
}
