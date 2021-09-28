//
//  BackupServiceType.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises

protocol BackupServiceType {
    /// get all existed backups
    func fetchBackupsFromInbox(for userId: UserId) -> Promise<[KeyDetails]>
    /// backup keys to user inbox
    func backupToInbox(keys: [KeyDetails], for userId: UserId) -> Promise<Void>
    /// show activity sheet to save keys as file
    func backupAsFile(keys: [KeyDetails], for viewController: UIViewController)
}
