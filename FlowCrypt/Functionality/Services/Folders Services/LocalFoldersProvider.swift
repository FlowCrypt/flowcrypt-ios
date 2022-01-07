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
    func removeFolders(for userEmail: String) throws
    func save(folders: [Folder], for user: User) throws
}

final class LocalFoldersProvider {
    private let encryptedStorage: EncryptedStorageType

    private var storage: Realm {
        encryptedStorage.storage
    }

    init(encryptedStorage: EncryptedStorageType) {
        self.encryptedStorage = encryptedStorage
    }
}

extension LocalFoldersProvider: LocalFoldersProviderType {
    func fetchFolders(for userEmail: String) -> [FolderViewModel] {
        storage.objects(FolderRealmObject.self).where {
            $0.user.email == userEmail
        }.compactMap(FolderViewModel.init)
    }

    func save(folders: [Folder], for user: User) throws {
        let objects = folders.map { FolderRealmObject(folder: $0, user: user) }
        try storage.write {
            objects.forEach {
                storage.add($0, update: .modified)
            }
        }
    }

    func removeFolders(for userEmail: String) throws {
        let objects = storage.objects(FolderRealmObject.self).where {
            $0.user.email == userEmail
        }

        try storage.write {
            storage.delete(objects)
        }
    }
}
