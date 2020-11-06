//
//  RemoteFoldersProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06/09/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

// TODO: - ANTON - Handle errors
enum FoldersProviderError: Error {
    case providerError(Error)
}

protocol RemoteFoldersProviderType {
    func fetchFolders() -> Promise<[FolderObject]>
}
