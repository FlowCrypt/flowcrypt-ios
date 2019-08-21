//
//  InboxViewModel.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/21/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct InboxViewModel {
    let folderName: String
    var path: String

    init(folderName: String, path: String) {
        self.folderName = folderName
        if folderName.isEmpty {
            self.path = "INBOX"
        } else {
            self.path = path
        }
    }

    static var empty = InboxViewModel(folderName: "", path: "")
}
