//
//  TrashFolderProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 20.02.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Promises

struct TrashFolderProvider {
    private let localStorage: LocalStorageType
    private let folderProvider: FoldersServiceType

    init(
        folderProvider: FoldersServiceType = FoldersService(storage: DataService.shared.storage),
        localStorage: LocalStorageType = LocalStorage()
    ) {
        self.folderProvider = folderProvider
        self.localStorage = localStorage
    }
}

extension TrashFolderProvider: TrashFolderProviderType {
    func getTrashFolderPath() -> Promise<String?> {
        if let path = localStorage.trashFolderPath {
            return Promise(path)
        } else {
            return Promise { resolve, _ in
                // will get all folders
                _ = try awaitPromise(folderProvider.fetchFolders(isForceReload: true))
                resolve(localStorage.trashFolderPath)
            }
        }
    }
}
