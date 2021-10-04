//
//  RemoteFoldersProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06/09/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises

protocol RemoteFoldersProviderType {
    func fetchFolders() -> Promise<[Folder]>
}

struct Folder {
    let name: String
    let path: String
    let image: Data?
}
