//
//  FoldersService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06/09/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation
import Promises

protocol TrashFolderProviderType {
    func getTrashFolderPath() -> Promise<String?>
}

protocol FoldersServiceType {
    func fetchFolders(isForceReload: Bool) -> Promise<[FolderViewModel]>
}

final class FoldersService: FoldersServiceType {
    // TODO: - Ticket? - consider rework with CacheService for trash path instead
    private let trashPathStorage: LocalStorageType
    private let localFoldersProvider: LocalFoldersProviderType
    private let remoteFoldersProvider: RemoteFoldersProviderType

    init(
        localFoldersProvider: LocalFoldersProviderType = LocalFoldersProvider(),
        remoteFoldersProvider: RemoteFoldersProviderType = MailProvider.shared.remoteFoldersProvider,
        trashPathStorage: LocalStorageType = LocalStorage()
    ) {
        self.localFoldersProvider = localFoldersProvider
        self.remoteFoldersProvider = remoteFoldersProvider
        self.trashPathStorage = trashPathStorage
    }

    func fetchFolders(isForceReload: Bool) -> Promise<[FolderViewModel]> {
        if isForceReload {
            return getAndSaveFolders()
        }

        let localFolders = self.localFoldersProvider.fetchFolders()

        if localFolders.isEmpty {
            return getAndSaveFolders()
        } else {
            getAndSaveFolders()
            return Promise(localFolders)
        }
    }

    @discardableResult
    private func getAndSaveFolders() -> Promise<[FolderViewModel]> {
        Promise<[FolderViewModel]> { [weak self] resolve, _ in
            guard let self = self else { throw AppErr.nilSelf }
            // fetch all folders
            let fetchedFolders = try awaitPromise(self.remoteFoldersProvider.fetchFolders())

            DispatchQueue.main.async {
                // TODO: - Ticket? - instead of removing all folders remove only
                // those folders which are in DB and not in remoteFolders
                self.localFoldersProvider.removeFolders()

                // save to Realm
                self.localFoldersProvider.save(folders: fetchedFolders)

                // save trash folder path
                self.saveTrashFolderPath(with: fetchedFolders.map(\.path))

                // return folders
                resolve(fetchedFolders.map(FolderViewModel.init))
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
