//
//  ContactsProviderType.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 07.12.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

protocol ContactsProviderType {
    func searchContacts(query: String) async throws -> [Recipient]
}
