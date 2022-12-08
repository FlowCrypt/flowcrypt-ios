//
//  BackupsManagerType.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

protocol BackupsManagerType {
    /// get all existed backups
    func fetchBackupsFromInbox(for userId: UserId) async throws -> [KeyDetails]
    /// backup keys to user inbox
    func backupToInbox(keys: [KeyDetails], for userId: UserId) async throws
    /// show activity sheet to save keys as file
    func backupAsFile(keys: [KeyDetails], for viewController: UIViewController)
}
