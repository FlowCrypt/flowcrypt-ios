//
//  ClientConfigurationServiceResults.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 22.07.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

extension ClientConfigurationService {
    enum CheckForUsingEKMResult {
        case usesEKM
        case inconsistentClientConfiguration(message: String)
        case doesNotUseEKM
    }
}
