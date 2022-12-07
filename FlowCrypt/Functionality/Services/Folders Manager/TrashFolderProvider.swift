//
//  TrashFolderProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 20.02.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

struct TrashFolderProvider {
    private let localStorage: LocalStorageType
    private let foldersManager: FoldersManagerType
    private let user: User

    init(
        user: User,
        foldersManager: FoldersManagerType,
        localStorage: LocalStorageType = LocalStorage()
    ) {
        self.foldersManager = foldersManager
        self.localStorage = localStorage
        self.user = user
    }
}

extension TrashFolderProvider: TrashFolderProviderType {
    var trashFolderPath: String? {
        get async throws {
            if let path = localStorage.trashFolderPath {
                return path
            } else {
                _ = try await foldersManager.fetchFolders(isForceReload: true, for: user)
                return localStorage.trashFolderPath
            }
        }
    }
}
