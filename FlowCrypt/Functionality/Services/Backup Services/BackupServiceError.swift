//
//  BackupServiceError.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

enum BackupServiceError: Error {
    case parse
    case emailNotFound
    case keyIsNotFullyEncrypted
}
