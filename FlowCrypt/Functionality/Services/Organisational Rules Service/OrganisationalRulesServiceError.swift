//
//  OrganisationalRulesServiceError.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 18.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum OrganisationalRulesServiceError: Error {
    case noCurrentUser
    case parse
    case emailFormat
}
