//
//  ContactsProviderType.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 07.12.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import GTMAppAuth

protocol ContactsProviderType {
    var authorization: GTMAppAuth.AuthSession? { get set }
    var isContactsScopeEnabled: Bool { get }
    func searchContacts(query: String) async throws -> [Recipient]
}
