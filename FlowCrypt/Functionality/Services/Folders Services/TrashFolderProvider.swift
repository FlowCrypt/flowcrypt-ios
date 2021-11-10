//
//  TrashFolderProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 20.02.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

struct TrashFolderProvider {
    private let localStorage: LocalStorageType
    private let folderProvider: FoldersServiceType

    init(
        folderProvider: FoldersServiceType = FoldersService(),
        localStorage: LocalStorageType = LocalStorage()
    ) {
        self.folderProvider = folderProvider
        self.localStorage = localStorage
    }
}

extension TrashFolderProvider: TrashFolderProviderType {
    func getTrashFolderPath() async throws -> String? {
        if let path = localStorage.trashFolderPath {
            return path
        } else {
            _ = try await folderProvider.fetchFolders(isForceReload: true)
            return localStorage.trashFolderPath
        }
    }
}
