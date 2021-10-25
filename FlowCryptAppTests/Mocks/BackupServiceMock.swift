//
//  BackupServiceMock.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 31.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import Promises
import UIKit

final class BackupServiceMock: BackupServiceType {
    var fetchBackupsResult: Result<[KeyDetails], Error> = .success([])
    func fetchBackupsFromInbox(for userId: UserId) -> Promise<[KeyDetails]> {
        Promise<[KeyDetails]>.resolveAfter(with: fetchBackupsResult)
    }

    var backupToInboxResult: Result<Void, Error> = .success(())
    func backupToInbox(keys: [KeyDetails], for userId: UserId) -> Promise<Void> {
        Promise<Void>.resolveAfter(with: backupToInboxResult)
    }

    var isBackupAsFile = false
    func backupAsFile(keys: [KeyDetails], for viewController: UIViewController) {
        isBackupAsFile = true
    }
}
