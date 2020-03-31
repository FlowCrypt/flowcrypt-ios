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
    
    func fetchMessagesIn(
        folder: String,
        uids: MCOIndexSet
    ) -> Promise<[MCOIMAPMessage]>
    
    func fetchMessage(
        in folder: String,
        kind: MCOIMAPMessagesRequestKind,
        uids: MCOIndexSet
    ) -> Promise<[MCOIMAPMessage]>
}

extension Imap: FoldersProvider {
    func fetchFolders() -> Promise<FoldersContext> {
        return Promise { [weak self] resolve, reject in
            self?.imapSess?
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

    func expungeMsgs(folder: String) -> Promise<Void> {
        return Promise { [weak self] resolve, reject in
            guard let self = self else { throw AppErr.nilSelf }
           
            self.imapSess?
                .expungeOperation(folder)
                .start(self.finalizeVoid("expungeMsgs", resolve, reject, retry: { self.expungeMsgs(folder: folder) }))
        }
    }
    
    func fetchMessagesIn(
        folder: String,
        uids: MCOIndexSet
    ) -> Promise<[MCOIMAPMessage]> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            let start = DispatchTime.now()
            let kind = self.messageKindProvider.imapMessagesRequestKind

            guard uids.count() > 0 else {
                log("fetchMsgs_empty", error: nil, res: [], start: start)
                resolve([]) // attempting to fetch an empty set of uids would cause IMAP error
                return
            }

            let messages = try await(self.fetchMessage(in: folder, kind: kind, uids: uids))
            resolve(messages)
        }
    }

    func fetchMessage(
        in folder: String,
        kind: MCOIMAPMessagesRequestKind,
        uids: MCOIndexSet
    ) -> Promise<[MCOIMAPMessage]> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            self.imapSess?
                .fetchMessagesOperation(withFolder: folder, requestKind: kind, uids: uids)?
                .start { error, msgs, _ in
                    guard self.notRetrying("fetchMsgs", error, resolve, reject, retry: {
                        self.fetchMessage(in: folder, kind: kind, uids: uids)
                    }) else { return }

                    if let messages = msgs as? [MCOIMAPMessage] {
                        return resolve(messages)
                    } else {
                        reject(AppErr.cast("msgs as? [MCOIMAPMessage]"))
                    }
                }
        }
    }
}
