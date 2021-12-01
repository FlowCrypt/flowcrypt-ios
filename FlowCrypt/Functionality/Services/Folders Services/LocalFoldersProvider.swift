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
    func fetchFolders(for userEmail: String) -> [FolderViewModel]
    func removeFolders(for userEmail: String)
    func save(folders: [Folder], for user: User)
}

struct LocalFoldersProvider: LocalFoldersProviderType {
    private let folderCache: EncryptedCacheService<FolderRealmObject>

    init(encryptedStorage: EncryptedStorageType) {
        self.folderCache = EncryptedCacheService(encryptedStorage: encryptedStorage)
    }

    func fetchFolders(for userEmail: String) -> [FolderViewModel] {
        return folderCache.getAll(for: userEmail).compactMap(FolderViewModel.init)
    }

    func save(folders: [Folder], for user: User) {
        folders.map { FolderRealmObject(folder: $0, user: user) }
            .forEach(folderCache.save)
    }

    func removeFolders(for userEmail: String) {
        folderCache.removeAll(for: userEmail)
    }
}
