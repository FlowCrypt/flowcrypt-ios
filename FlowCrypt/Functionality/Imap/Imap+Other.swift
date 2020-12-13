//
//  Imap+Other.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

extension Imap {
    // TODO: - ANTON
    /// get trash folder path either form local storage in case it was already saved or tries to fetch all folders info and save it
    func trashFolderPath() -> Promise<String?> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf )}

            if let path = self.dataService.trashFolderPath {
                resolve(path)
            } else {
                _ = try await(self.fetchFolders())
                resolve(self.dataService.trashFolderPath)
            }
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

                    guard let messages = msgs as? [MCOIMAPMessage] else {
                        return reject(AppErr.cast("[MCOIMAPMessage]"))
                    }
                    return resolve(messages)
                }
        }
    }
}
