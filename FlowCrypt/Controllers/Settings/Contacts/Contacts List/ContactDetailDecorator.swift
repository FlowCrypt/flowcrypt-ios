//
//  ContactDetailDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import FlowCryptUI

protocol ContactDetailDecoratorType {
    var title: String { get }
    func nodeInput(with contact: Contact) -> ContactDetailNode.Input
}

struct ContactDetailDecorator: ContactDetailDecoratorType {
    let title = "contact_detail_screen_title".localized

    func nodeInput(with contact: Contact) -> ContactDetailNode.Input {
        let createdString: String = {
            if let created = contact.pubkeyCreated {
                let df = DateFormatter()
                df.dateStyle = .medium
                df.timeStyle = .medium
                return df.string(from: created)
            } else {
                return "-"
            }

        }()
        return ContactDetailNode.Input(
            user: (contact.name ?? contact.email).attributed(.regular(16)),
            ids: contact.longids.joined(separator: ",\n").attributed(.regular(14)),
            fingerprints: contact.fingerprints.joined(separator: ",\n").attributed(.regular(14)),
            algoInfo: contact.algo?.algorithm.attributed(.regular(14)),
            created: createdString.attributed(.regular(14))
        )
    }
}
