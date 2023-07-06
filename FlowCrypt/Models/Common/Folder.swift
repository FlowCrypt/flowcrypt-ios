//
//  Folder.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 16.11.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct Folder {
    var path: String
    var name: String
    var image: Data?
    var backgroundColor: String?
    var isHidden: Bool?
    var itemType: String = FolderViewModel.ItemType.folder.rawValue
}
