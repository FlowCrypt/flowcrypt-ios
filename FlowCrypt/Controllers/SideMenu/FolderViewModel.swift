//
//  FolderViewModel.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/30/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct FolderViewModel {
    let name: String
    let path: String
}

extension FolderViewModel {
    init?(_ folder: MCOIMAPFolder) {
        guard folder.path.isEmpty else { return nil }
        self.name = {
            let gmailPath = "[Gmail]"
            if folder.path.contains(gmailPath) {
                return folder.path.replacingOccurrences(of: gmailPath, with: "").trimLeadingSlash
            } else {
                return folder.path
            }
        }()
        self.path = folder.path
    }
}
