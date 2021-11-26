//
//  LocalFoldersProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06/09/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift

protocol LocalFoldersProviderType {
    func fetchFolders() -> [FolderViewModel]
    func removeFolders()
    func save(folders: [Folder])
}

struct LocalFoldersProvider: LocalFoldersProviderType {
    private let folderCache: EncryptedCacheService<FolderRealmObject>

    init(encryptedStorage: EncryptedStorageType = EncryptedStorage()) {
        self.folderCache = EncryptedCacheService(encryptedStorage: encryptedStorage)
    }

    func fetchFolders() -> [FolderViewModel] {
        folderCache.getAllForActiveUser()?
            .compactMap(FolderViewModel.init)
            ?? []
    }

    func save(folders: [Folder]) {
        guard let currentUser = folderCache.encryptedStorage.activeUser else {
            return
        }

        folders.map { FolderRealmObject(folder: $0, user: currentUser) }
            .forEach(folderCache.save)
    }

    func removeFolders() {
        folderCache.removeAllForActiveUser()
    }
}
