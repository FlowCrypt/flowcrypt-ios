//
//  ContactKeyDetailDecorator.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 13/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI

struct ContactKeyDetailDecorator {
    let title = "contact_key_detail_screen_title".localized

    func details(for key: PubKey, part: ContactKeyDetailViewController.Part) -> LabelCellNode.Input {
        return LabelCellNode.Input(
            title: attributedTitle(for: part),
            text: content(for: key, part: part),
            accessibilityIdentifier: accessibilityIdentifier(for: part),
            labelAccessibilityIdentifier: "\(accessibilityIdentifier(for: part))-label"
        )
    }

    private func attributedTitle(for contactKeyPart: ContactKeyDetailViewController.Part) -> NSAttributedString {
        let title = switch contactKeyPart {
        case .armored:
            "contact_key_pub"
        case .signature:
            "contact_key_signature"
        case .created:
            "contact_key_created"
        case .checked:
            "contact_key_fetched"
        case .expire:
            "contact_key_expires"
        case .longids:
            "contact_key_longids"
        case .fingerprints:
            "contact_key_fingerprints"
        case .algo:
            "contact_key_algo"
        }

        return title.localized.attributed(.bold(16))
    }

    private func content(for pubKey: PubKey, part: ContactKeyDetailViewController.Part) -> NSAttributedString {
        let result: String = switch part {
        case .armored:
            pubKey.armored
        case .signature:
            string(from: pubKey.lastSig)
        case .created:
            string(from: pubKey.created)
        case .checked:
            string(from: pubKey.lastChecked)
        case .expire:
            string(from: pubKey.expiresOn)
        case .longids:
            pubKey.longids.joined(separator: ", ")
        case .fingerprints:
            pubKey.fingerprints.joined(separator: ", ")
        case .algo:
            pubKey.algo?.algorithm ?? "-"
        }
        return result.attributed(.regular(14))
    }

    private func string(from date: Date?) -> String {
        guard let date else { return "-" }

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .medium
        return df.string(from: date)
    }

    private func accessibilityIdentifier(for part: ContactKeyDetailViewController.Part) -> String {
        switch part {
        case .armored:
            return "aid-signature-key"
        case .signature:
            return "aid-signature-date"
        case .created:
            return "aid-signature-created-date"
        case .checked:
            return "aid-signature-fetched-date"
        case .expire:
            return "aid-signature-expires-date"
        case .longids:
            return "aid-signature-longids"
        case .fingerprints:
            return "aid-signature-fingerprints"
        case .algo:
            return "aid-signature-algo"
        }
    }
}
