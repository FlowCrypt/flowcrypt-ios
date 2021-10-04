//
//  LocalFoldersProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06/09/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

protocol LocalFoldersProviderType {
    func fetchFolders() -> [FolderViewModel]
    func removeFolders()
    func save(folders: [Folder])
}

struct LocalFoldersProvider: LocalFoldersProviderType {
    private let folderCache: CacheService<FolderObject>
    private let encryptedStorage: EncryptedStorageType

    init(encryptedStorage: EncryptedStorageType = EncryptedStorage()) {
        self.folderCache = CacheService(storage: encryptedStorage.storage)
        self.encryptedStorage = encryptedStorage
    }

    func fetchFolders() -> [FolderViewModel] {
        folderCache.getAllForActiveUser()?
            .compactMap(FolderViewModel.init)
            ?? []
    }

    func save(folders: [Folder]) {
        guard let currentUser = encryptedStorage.activeUser else {
            return
        }

        folders.map { FolderObject(folder: $0, currentUser: currentUser) }
            .forEach(folderCache.save)
    }

    func removeFolders() {
        folderCache.removeAllForActiveUser()
    }
}

private extension FolderObject {
    convenience init(folder: Folder, currentUser: UserObject) {
        self.init(
            name: folder.name,
            path: folder.path,
            image: folder.image,
            user: currentUser
        )
    }
}
