//
//  BackupProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 26.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises

protocol BackupProvider {
    func searchBackups(for email: String) -> Promise<Data>
}
