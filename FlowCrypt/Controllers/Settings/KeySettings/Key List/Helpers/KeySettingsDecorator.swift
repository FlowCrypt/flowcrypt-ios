//
//  KeySettingsDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol KeySettingsDecoratorType {
    func attributedTitle(for key: KeySettingsItem) -> NSAttributedString
    func attributedSubTitle(for key: KeySettingsItem) -> NSAttributedString
    func attributedDate(for key: KeySettingsItem) -> NSAttributedString
}

struct KeySettingsDecorator: KeySettingsDecoratorType {
    private let dateFormatter: DateFormatter

    init(dateFormatter: DateFormatter = DateFormatter()) {
        self.dateFormatter = dateFormatter
    }

    func attributedTitle(for key: KeySettingsItem) -> NSAttributedString {
        key.users.attributed(.medium(16))
    }

    func attributedSubTitle(for key: KeySettingsItem) -> NSAttributedString {
        (key.details.first?.keywords ?? "")
            .attributed(.regular(14), color: .main)
    }

    func attributedDate(for key: KeySettingsItem) -> NSAttributedString {
        dateFormatter.formatDate(key.createdDate)
            .attributed(.medium(16))
    }
}
