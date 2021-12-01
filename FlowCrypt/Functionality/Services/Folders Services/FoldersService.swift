//
//  FoldersService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06/09/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation

protocol TrashFolderProviderType {
    func getTrashFolderPath() async throws -> String?
}

protocol FoldersServiceType {
    func fetchFolders(isForceReload: Bool, for user: User) async throws -> [FolderViewModel]
}

final class FoldersService: FoldersServiceType {
    // TODO: - Ticket? - consider rework with CacheService for trash path instead
    private let trashPathStorage: LocalStorageType
    private let localFoldersProvider: LocalFoldersProviderType
    private let remoteFoldersProvider: RemoteFoldersProviderType

    init(
        encryptedStorage: EncryptedStorageType,
        localFoldersProvider: LocalFoldersProviderType? = nil,
        remoteFoldersProvider: RemoteFoldersProviderType,
        trashPathStorage: LocalStorageType = LocalStorage()
    ) {
        self.localFoldersProvider = localFoldersProvider ?? LocalFoldersProvider(encryptedStorage: encryptedStorage)
        self.remoteFoldersProvider = remoteFoldersProvider
        self.trashPathStorage = trashPathStorage
    }

    func fetchFolders(isForceReload: Bool, for user: User) async throws -> [FolderViewModel] {
        if isForceReload {
            return try await getAndSaveFolders(for: user)
        }
        let localFolders = self.localFoldersProvider.fetchFolders(for: user.email)
        if localFolders.isEmpty {
            return try await getAndSaveFolders(for: user)
        } else {
            try await getAndSaveFolders(for: user)
            return localFolders
        }
    }

    @discardableResult
    private func getAndSaveFolders(for user: User) async throws -> [FolderViewModel] {
        // fetch all folders
        let fetchedFolders = try await self.remoteFoldersProvider.fetchFolders()
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                // TODO: - Ticket? - instead of removing all folders remove only
                // those folders which are in DB and not in remoteFolders
                self.localFoldersProvider.removeFolders(for: user.email)

                // save to Realm
                self.localFoldersProvider.save(folders: fetchedFolders, for: user)

                // save trash folder path
                self.saveTrashFolderPath(with: fetchedFolders.map(\.path))

                // return folders
                continuation.resume(returning: fetchedFolders.map(FolderViewModel.init))
            }
        }
    }

    private func saveTrashFolderPath(with paths: [String]) {
        guard let path = paths.firstCaseInsensitive("trash") ?? paths.firstCaseInsensitive("deleted") else {
            Logger.logWarning("Trash folder not found")
            return
        }
        trashPathStorage.saveTrashFolder(path: path)
    }
}

private extension FolderViewModel {
    init(folder: Folder) {
        self.init(
            name: folder.name,
            path: folder.path,
            image: nil, // no op for now
            itemType: .folder
        )
    }
}
