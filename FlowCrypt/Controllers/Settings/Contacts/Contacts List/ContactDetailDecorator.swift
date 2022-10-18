//
//  ContactDetailDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI

struct ContactDetailDecorator {
    let title = "contact_detail_screen_title".localized

    func userNodeInput(with contact: RecipientWithSortedPubKeys) -> ContactUserCellNode.Input {
        ContactUserCellNode.Input(
            user: contact.formatted.attributed(.regular(16))
        )
    }

    func keyNodeInput(with key: PubKey) -> ContactKeyCellNode.Input {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .medium

        let fingerpringString = key.fingerprint ?? "-"

        let createdString: String = {
            guard let created = key.created else { return "-" }
            return df.string(from: created)
        }()

        let expiresString: String = {
            guard let expires = key.expiresOn else { return "never" }
            return df.string(from: expires)
        }()

        return ContactKeyCellNode.Input(
            fingerprint: fingerpringString.attributed(.regular(13)),
            createdAt: createdString.attributed(.regular(14)),
            expires: expiresString.attributed(.regular(14))
        )
    }
}
