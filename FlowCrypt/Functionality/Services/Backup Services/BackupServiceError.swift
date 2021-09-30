//
//  BackupServiceError.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum BackupServiceError: Error {
    case parse
    case keyIsNotFullyEncrypted
}
