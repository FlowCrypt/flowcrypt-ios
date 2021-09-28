//
//  Imap+folders.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
import Foundation
import Promises

// MARK: - RemoteFoldersProviderType
extension Imap: RemoteFoldersProviderType {
    func fetchFolders() -> Promise<[Folder]> {
        Promise { [weak self] resolve, reject in
            self?.imapSess?
                .fetchAllFoldersOperation()
                .start { [weak self] error, value in
                    guard let self = self else { return reject(AppErr.nilSelf) }
                    guard self.notRetrying("fetchFolders", error, resolve, reject, retry: { self.fetchFolders() }) else {
                        return
                    }
                    if let error = error {
                        reject(ImapError.providerError(error))
                        return
                    }

                    let folders = value?.map(Folder.init) ?? []
                    resolve(folders)
            }
        }
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
