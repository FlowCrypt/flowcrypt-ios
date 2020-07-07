//
//  FolderViewModel.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/30/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptUI
import UIKit

struct FolderViewModel {
    enum ItemType {
        case folder, settings, logOut
    }

    static var empty = FolderViewModel(name: "", path: "", image: nil, itemType: .folder)

    let name: String
    let path: String
    let image: UIImage?
    let itemType: ItemType
}

extension FolderViewModel {
    init?(_ folder: MCOIMAPFolder, image: UIImage? = nil, itemType: ItemType = .folder) {
        let gmailRootPath = GeneralConstants.Global.gmailRootPath
        guard !folder.path.isEmpty else { return nil }
        guard folder.path != gmailRootPath else { return nil }
        name = folder.path.contains(gmailRootPath)
            ? folder.path.replacingOccurrences(of: gmailRootPath, with: "").trimLeadingSlash.capitalized
            : folder.path.capitalized
        path = folder.path
        self.image = image
        self.itemType = itemType
    }
}
