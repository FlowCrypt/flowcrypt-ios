//
//  KeySettingsDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol KeySettingsViewDecoratorType {
    func attributedUsers(key: KeyDetails) -> NSAttributedString
    func attributedKeyWords(key: KeyDetails) -> NSAttributedString
    func attributedDateCreated(key: KeyDetails) -> NSAttributedString
}

extension DateFormatter {
    static let keySettingsFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

struct KeySettingsViewDecorator: KeySettingsViewDecoratorType {
    private let dateFormatter: DateFormatter

    init(dateFormatter: DateFormatter = .keySettingsFormatter) {
        self.dateFormatter = dateFormatter
    }

    func attributedUsers(key: KeyDetails) -> NSAttributedString {
        key.users
            .joined(separator: " ")
            .attributed(.medium(16))
    }

    func attributedKeyWords(key: KeyDetails) -> NSAttributedString {
        key.ids
            .compactMap { $0.fingerprint.separate(every: 4, with: " ") }
            .joined(separator: "\n")
            .attributed(.regular(14), color: .main)
    }

    func attributedDateCreated(key: KeyDetails) -> NSAttributedString {
        dateFormatter.string(from: key.created.toDate())
            .attributed(.medium(12))
    }
}

private extension String {
    func separate(
        every stride: Int = 4,
        with separator: Character = " "
    ) -> String {
        String(
            self.enumerated()
            .map { $0 > 0 && $0 % stride == 0 ? [separator, $1] : [$1]}
            .joined()
        )
    }
}
