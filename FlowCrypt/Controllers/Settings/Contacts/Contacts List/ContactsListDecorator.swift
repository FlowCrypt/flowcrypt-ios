//
//  ContactsListDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 22/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import UIKit

struct ContactsListDecorator {
    let title = "contacts_screen_title".localized

    func contactNodeInput(with recipient: RecipientWithSortedPubKeys) -> ContactCellNode.Input {
        let name: String

        if let recipientName = recipient.name, recipientName.isNotEmpty {
            let components = recipientName
                .split(separator: " ")
                .filter { !$0.contains("@") }

            if components.isEmpty {
                name = nameFrom(email: recipient.email)
            } else {
                name = components.joined(separator: " ")
            }
        } else {
            name = nameFrom(email: recipient.email)
        }

        let buttonColor = UIColor.colorFor(
            darkStyle: .lightGray,
            lightStyle: .darkGray
        )
        let keysCount = "%@ public key(s)".localizePluralsWithArguments(recipient.pubKeys.count)
        return ContactCellNode.Input(
            name: name.attributed(.medium(16)),
            email: recipient.email.attributed(.medium(14)),
            keys: "(\(keysCount))".attributed(.medium(14), color: .mainTextColor.withAlphaComponent(0.5)),
            insets: .deviceSpecificTextInsets(top: 16, bottom: 8),
            buttonImage: UIImage(systemName: "trash")?.tinted(buttonColor)
        )
    }

    private func nameFrom(email: String) -> String {
        email.split(separator: "@")
            .dropLast()
            .joined()
    }
}
