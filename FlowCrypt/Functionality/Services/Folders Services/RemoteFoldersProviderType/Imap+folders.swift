//
//  Imap+folders.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation
import MailCore

// MARK: - RemoteFoldersProviderType
extension Imap: RemoteFoldersProviderType {
    func fetchFolders() async throws -> [Folder] {
        try await execute("fetchMsgAttachment", { sess, respond in
            sess.fetchAllFoldersOperation()
                .start { error, value in respond(error, value?.map(Folder.init))}
        })
    }
}

// MARK: - Convenience
private extension Folder {
    init(with folder: MCOIMAPFolder) {
        self.init(
            name: folder.name ?? folder.path,
            path: folder.path,
            image: nil
        )
    }
}

extension MCOIMAPFolder {
    var name: String? {
        let gmailRootPath = "[Gmail]"
        guard !path.isEmpty else { return nil }
        guard path != gmailRootPath else { return nil }

        return path.contains(gmailRootPath)
            ? path.replacingOccurrences(of: gmailRootPath, with: "").trimLeadingSlash.capitalized
            : path.capitalized
    }
}
