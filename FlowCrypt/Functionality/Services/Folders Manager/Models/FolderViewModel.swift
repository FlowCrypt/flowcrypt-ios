//
//  FolderViewModel.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/30/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import MailCore
import UIKit

struct FolderViewModel {
    enum ItemType: String {
        case folder, settings, logOut
    }

    let name: String
    let path: String
    let image: UIImage?
    let itemType: ItemType
}

// MARK: - Map from server(imap) model
extension FolderViewModel {
    init?(_ folder: MCOIMAPFolder, image: UIImage? = nil, itemType: ItemType = .folder) {
        guard let name = folder.name else { return nil }
        self.name = name
        self.path = folder.path
        self.image = image
        self.itemType = itemType
    }
}

// MARK: - Map from realm model
extension FolderViewModel {
    init(_ object: FolderRealmObject) {
        self.init(
            name: object.name,
            path: object.path,
            image: object.image.flatMap(UIImage.init) ?? UIImage(systemName: object.path.mailFolderIcon),
            itemType: ItemType(rawValue: object.itemType) ?? .folder
        )
    }
}

extension FolderViewModel: Equatable {
    static func == (lhs: FolderViewModel, rhs: FolderViewModel) -> Bool {
        return lhs.name == rhs.name && lhs.path == rhs.path
    }
}
