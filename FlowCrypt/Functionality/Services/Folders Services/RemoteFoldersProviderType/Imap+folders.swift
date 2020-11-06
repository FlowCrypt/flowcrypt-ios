//
//  Imap+folders.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

// MARK: - RemoteFoldersProviderType
extension Imap: RemoteFoldersProviderType {
    func fetchFolders() -> Promise<[FolderObject]> {
        Promise { [weak self] resolve, reject in
            self?.imapSess?
                .fetchAllFoldersOperation()
                .start { [weak self] error, value in
                    guard let self = self else { return reject(AppErr.nilSelf) }
                    guard self.notRetrying("fetchFolders", error, resolve, reject, retry: { self.fetchFolders() }) else {
                        return
                    }
                    if let error = error {
                        reject(FoldersProviderError.providerError(error))
                    }
                    guard let folders = value as? [MCOIMAPFolder] else {
                        return reject(AppErr.cast("[MCOIMAPFolder]"))
                    }
                    resolve(folders.compactMap(FolderObject.init))
            }
        }
    }
}

// MARK: - Convenience
private extension FolderObject {
    convenience init?(with folder: MCOIMAPFolder) {
        guard let name = folder.name else { return nil }
        self.init(
            name: name,
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
