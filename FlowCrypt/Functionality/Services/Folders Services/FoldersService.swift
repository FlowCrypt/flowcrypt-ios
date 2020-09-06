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
    let localFoldersProvider: LocalFoldersProviderType
    let remoteFoldersProvider: RemoteFoldersProviderType

    init(
        storage: @escaping @autoclosure CacheStorage,
        remoteFoldersProvider: RemoteFoldersProviderType = Imap.shared
    ) {
        self.localFoldersProvider = LocalFoldersProvider(storage: storage())
        self.remoteFoldersProvider = remoteFoldersProvider
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

            // return folders
            resolve(folders.map(FolderViewModel.init))
        }
    }
}
