//
//  LocalizationExtensions.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 08.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

@inline(__always)
private func localize(_ key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

@inline(__always)
private func LocalizedString(_ key: String) -> String {
    return localize(key)
}

public extension String {
    var localized: String {
        return LocalizedString(self)
    }

    @inline(__always)
    func localizeWithArguments(_ arguments: String...) -> String {
        String(format: localize(self), arguments: arguments)
    }

    /// use to localize plurals with Localizable.stringsdict
    @inline(__always)
    func localizePluralsWithArguments(_ arguments: Int...) -> String {
        String(format: localize(self), arguments: arguments)
    }
}
