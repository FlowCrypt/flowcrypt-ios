//
//  FoldersService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06/09/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

protocol FoldersServiceType {
    func fetchFolders() -> Promise<[FolderViewModel]>
}

struct FoldersService: FoldersServiceType {
    let dataService: DataService
    let localFoldersProvider: LocalFoldersProviderType
    let remoteFoldersProvider: RemoteFoldersProviderType

    init(
        storage: @escaping @autoclosure CacheStorage,
        remoteFoldersProvider: RemoteFoldersProviderType = GlobalServices.shared.remoteFoldersProvider,
        dataService: DataService = DataService.shared
    ) {
        self.localFoldersProvider = LocalFoldersProvider(storage: storage())
        self.remoteFoldersProvider = remoteFoldersProvider
        self.dataService = dataService
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
        Promise<[FolderViewModel]> { resolve, _ in
            // fetch all folders
            let remoteFolders = try await(self.remoteFoldersProvider.fetchFolders())

            // save to Realm
            let folders = remoteFolders.compactMap(FolderObject.init)
            self.localFoldersProvider.save(folders: folders)

            // save trash folder path
            saveTrashFolderPath(with: folders)

            // return folders
            resolve(folders.map(FolderViewModel.init))
        }
    }

    private func saveTrashFolderPath(with folders: [FolderObject]) {
        if dataService.email?.contains("gmail") ?? false {
            dataService.saveTrashFolder(path: MailDestination.Gmail.trash.path)
        } else {
            let paths = folders.compactMap { $0.path }
            guard let path = paths.firstCaseInsensitive("trash") ?? paths.firstCaseInsensitive("deleted") else {
                debugPrint("###Warning### Trash folder not found")
                return
            }
            dataService.saveTrashFolder(path: path)
        }
    }
}
