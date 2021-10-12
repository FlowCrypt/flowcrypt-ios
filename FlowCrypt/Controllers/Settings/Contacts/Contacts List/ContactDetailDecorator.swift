//
//  ContactDetailDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import Foundation

protocol ContactDetailDecoratorType {
    var title: String { get }
    func userNodeInput(with contact: Contact) -> ContactUserCellNode.Input
    func keyNodeInput(with key: ContactKey) -> ContactKeyCellNode.Input
}

struct ContactDetailDecorator: ContactDetailDecoratorType {
    let title = "contact_detail_screen_title".localized

    func userNodeInput(with contact: Contact) -> ContactUserCellNode.Input {
        ContactUserCellNode.Input(
            user: (contact.name ?? contact.email).attributed(.regular(16))
        )
    }

    func keyNodeInput(with key: ContactKey) -> ContactKeyCellNode.Input {
        ContactKeyCellNode.Input(
            fingerprint: key.fingerprint?.attributed(.regular(12)),
            createdAt: "".attributed(.regular(14)),
            expires: "".attributed(.regular(14))
        )
    }
}
