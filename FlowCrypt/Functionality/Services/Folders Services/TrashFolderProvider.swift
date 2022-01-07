//
//  TrashFolderProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 20.02.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

struct TrashFolderProvider {
    private let localStorage: LocalStorageType
    private let foldersService: FoldersServiceType
    private let user: User

    init(
        // todo - rename argument to folderService:
        user: User,
        foldersService: FoldersServiceType,
        localStorage: LocalStorageType = LocalStorage()
    ) {
        self.foldersService = foldersService
        self.localStorage = localStorage
        self.user = user
    }
}

extension TrashFolderProvider: TrashFolderProviderType {
    func getTrashFolderPath() async throws -> String? {
        if let path = localStorage.trashFolderPath {
            return path
        } else {
            _ = try await foldersService.fetchFolders(isForceReload: true, for: self.user)
            return localStorage.trashFolderPath
        }
    }
}
