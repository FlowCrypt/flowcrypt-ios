//
//  RemoteFoldersProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06/09/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

protocol RemoteFoldersProviderType {
    func fetchFolders() async throws -> [Folder]
}
