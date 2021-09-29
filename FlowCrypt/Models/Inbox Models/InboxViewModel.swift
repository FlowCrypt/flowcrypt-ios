//
//  InboxViewModel.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/21/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct InboxViewModel {
    let folderName: String
    var path: String

    init(folderName: String, path: String) {
        self.folderName = folderName
        if folderName.isEmpty {
            self.path = "Inbox"
        } else {
            self.path = path
        }
    }
}

extension InboxViewModel {
    init(_ folder: FolderViewModel) {
        self.init(folderName: folder.name, path: folder.path)
    }
}
