//
//  BackupServiceMock.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 31.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises
//@testable import FlowCrypt

// TODO: - ANTON - remove from FlowCrypt target
final class BackupServiceMock: BackupServiceType {
    var fetchBackupsResult: Result<[KeyDetails], Error> = .failure(MockError.some)
    func fetchBackups(for userId: UserId) -> Promise<[KeyDetails]> {
        .resolveAfter(with: fetchBackupsResult)
    }

    var backupToInboxResult: Result<Void, Error> = .success(())
    func backupToInbox(keys: [KeyDetails], for userId: UserId) -> Promise<Void> {
        .resolveAfter(with: backupToInboxResult)
    }

    var isBackupAsFile = false
    func backupAsFile(keys: [KeyDetails], for viewController: UIViewController) {
        isBackupAsFile = true
    }
}
