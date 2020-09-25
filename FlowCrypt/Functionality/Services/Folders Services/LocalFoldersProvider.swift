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
    func save(folders: [FolderObject])
}

struct LocalFoldersProvider: LocalFoldersProviderType {
    private let folderCache: CacheService<FolderObject>

    init(storage: @escaping @autoclosure CacheStorage) {
        self.folderCache = CacheService(storage: storage())
    }

    func fetchFolders() -> [FolderViewModel] {
        folderCache.getAll()?.compactMap(FolderViewModel.init) ?? []
    }

    func save(folders: [FolderObject]) {
        folders.forEach(folderCache.save)
    }
}
