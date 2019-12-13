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
    func attributedTitle(for key: KeySettingsItem) -> NSAttributedString {
        NSAttributedString(string: "Title")
    }

    func attributedSubTitle(for key: KeySettingsItem) -> NSAttributedString {
        NSAttributedString(string: "Sub Title")
    }

    func attributedDate(for key: KeySettingsItem) -> NSAttributedString {
        NSAttributedString(string: "Date ")
    }
}
