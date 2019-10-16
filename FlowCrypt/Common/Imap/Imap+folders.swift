//
//  Imap+folders.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

struct FoldersContext {
    let folders: [MCOIMAPFolder]
}

protocol FoldersProvider {
    func fetchFolders() -> Promise<FoldersContext>
}

extension Imap: FoldersProvider {
    func fetchFolders() -> Promise<FoldersContext> {
        return Promise { [weak self] resolve, reject in
            self?.getImapSess()
                .fetchAllFoldersOperation()
                .start { [weak self] error, value in
                    guard let self = self else { return reject(AppErr.nilSelf) }
                    guard self.notRetrying("fetchFolders", error, resolve, reject, retry: { self.fetchFolders() }) else {
                        return
                    }
                    if let error = error {
                        reject(AppErr(error))
                    } else if let folders = value as? [MCOIMAPFolder] {
                        resolve(FoldersContext(folders: folders))
                    } else {
                        reject(AppErr.cast("value as? [MCOIMAPFolder] failed"))
                    }
                }
        }
    }

    // expunges messages from a folder which already have a /Deleted flag set on them
    func expungeMsgs(folder: String) -> Promise<Void> {
        return Promise { [weak self] resolve, reject in
            guard let self = self else { throw AppErr.nilSelf }
            self.getImapSess()
                .expungeOperation(folder)
                .start(self.finalizeVoid("expungeMsgs", resolve, reject, retry: { self.expungeMsgs(folder: folder) }))
        }
    }
}
