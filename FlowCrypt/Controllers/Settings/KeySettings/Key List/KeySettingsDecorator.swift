//
//  KeySettingsDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol KeySettingsDecoratorType {
    func attributedUsers(key: KeyDetails) -> NSAttributedString
    func attributedKeyWords(key: KeyDetails) -> NSAttributedString
    func attributedDateCreated(key: KeyDetails) -> NSAttributedString
}

struct KeySettingsDecorator: KeySettingsDecoratorType {
    private let dateFormatter: DateFormatter

    init(dateFormatter: DateFormatter = DateFormatter()) {
        self.dateFormatter = dateFormatter
    }

    func attributedUsers(key: KeyDetails) -> NSAttributedString {
        return key.users
            .joined(separator: " ")
            .attributed(.medium(16))
    }

    func attributedKeyWords(key: KeyDetails) -> NSAttributedString {
        key.ids
            .compactMap { $0.keywords }
            .joined(separator:"\n")
            .attributed(.regular(14), color: .main)
    }

    func attributedDateCreated(key: KeyDetails) -> NSAttributedString {
        return dateFormatter.formatDate(key.created.toDate())
            .attributed(.medium(16))
    }
}
