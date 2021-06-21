//
//  FoldersService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06/09/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

protocol TrashFolderProviderType {
    func getTrashFolderPath() -> Promise<String?>
}

protocol FoldersServiceType {
    func fetchFolders() -> Promise<[FolderViewModel]>
}

final class FoldersService: FoldersServiceType {
    // TODO: - Ticket? - consider rework with CacheService for trash path instead
    private let localStorage: LocalStorageType

    let localFoldersProvider: LocalFoldersProviderType
    let remoteFoldersProvider: RemoteFoldersProviderType

    init(
        storage: @escaping @autoclosure CacheStorage,
        remoteFoldersProvider: RemoteFoldersProviderType = MailProvider.shared.remoteFoldersProvider,
        localStorage: LocalStorageType = LocalStorage()
    ) {
        self.localFoldersProvider = LocalFoldersProvider(storage: storage())
        self.remoteFoldersProvider = remoteFoldersProvider
        self.localStorage = localStorage
    }

    func fetchFolders() -> Promise<[FolderViewModel]> {
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
            let remoteFolders = try awaitPromise(self.remoteFoldersProvider.fetchFolders())

            DispatchQueue.main.async {
                // TODO: - Ticket? - instead of removing all folders remove only
                // those folders which are in DB and not in remoteFolders
                self.localFoldersProvider.removeFolders()

                // save to Realm
                let folders = remoteFolders.compactMap(FolderObject.init)
                self.localFoldersProvider.save(folders: folders)

                // save trash folder path
                self.saveTrashFolderPath(with: folders)

                // return folders
                resolve(folders.map(FolderViewModel.init))
            }
        }
    }

    private func saveTrashFolderPath(with folders: [FolderObject]) {
        let paths = folders.map(\.path)
        guard let path = paths.firstCaseInsensitive("trash") ?? paths.firstCaseInsensitive("deleted") else {
            Logger.logWarning("Trash folder not found")
            return
        }
        localStorage.saveTrashFolder(path: path)
    }
}
