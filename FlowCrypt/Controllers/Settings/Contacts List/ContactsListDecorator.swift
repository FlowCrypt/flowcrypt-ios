//
//  ContactsListDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 22/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit
import FlowCryptUI

protocol ContactsListDecoratorType {
    var title: String { get }
    func contactNodeInput(with contact: Contact) -> ContactCellNode.Input
}

struct ContactsListDecorator: ContactsListDecoratorType {
    let title = "contacts_screen_title".localized

    func contactNodeInput(with contact: Contact) -> ContactCellNode.Input {
        let name: String

        if let contactName = contact.name, contactName.isNotEmpty {
            let components = contactName
                .split(separator: " ")
                .filter { !$0.contains("@") }

            if components.isEmpty {
                name = nameFrom(email: contact.email)
            } else {
                name = components.joined(separator: " ")
            }
        } else {
            name = nameFrom(email: contact.email)
        }

        let buttonColor = UIColor.colorFor(
            darkStyle: .lightGray,
            lightStyle: .darkGray
        )

        return ContactCellNode.Input(
            name: name.attributed(.medium(16)),
            email: contact.email.attributed(.medium(14)),
            insets: UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16),
            buttonImage: #imageLiteral(resourceName: "trash").tinted(buttonColor)
        )
    }

    private func nameFrom(email: String) -> String {
        email.split(separator: "@")
            .dropLast()
            .joined()
    }
}
