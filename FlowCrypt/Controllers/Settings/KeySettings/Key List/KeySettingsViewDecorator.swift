//
//  KeySettingsDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation

extension DateFormatter {
    static let keySettingsFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

struct KeySettingsViewDecorator {
    private let dateFormatter: DateFormatter

    init(dateFormatter: DateFormatter = .keySettingsFormatter) {
        self.dateFormatter = dateFormatter
    }

    func attributedUsers(with key: KeyDetails) -> NSAttributedString {
        key.users
            .joined(separator: " ")
            .attributed(.medium(16))
    }

    func attributedFingerprints(with key: KeyDetails) -> NSAttributedString {
        key.ids
            .compactMap { $0.fingerprint.separate(every: 4, with: " ") }
            .joined(separator: "\n")
            .attributed(.regular(14), color: .main)
    }

    func attributedDateCreated(with key: KeyDetails) -> NSAttributedString {
        dateFormatter.string(from: key.created.toDate())
            .attributed(.medium(12))
    }
}
