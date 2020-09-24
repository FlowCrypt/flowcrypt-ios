//
//  Imap+folders.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

extension Imap: RemoteFoldersProviderType {
    func fetchFolders() -> Promise<[MCOIMAPFolder]> {
        Promise { [weak self] resolve, reject in
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
                        self.saveTrashFolderPath(with: folders)
                        resolve(folders)
                    } else {
                        reject(AppErr.cast("value as? [MCOIMAPFolder] failed"))
                    }
            }
        }
    }

    private func saveTrashFolderPath(with folders: [MCOIMAPFolder]) {
        if dataService.email?.contains("gmail") ?? false {
            dataService.saveTrashFolder(path: MailDestination.Gmail.trash.path)
        } else {
            let paths = folders.compactMap { $0.path }
            guard let path = paths.firstCaseInsensitive("trash") ?? paths.firstCaseInsensitive("deleted") else {
                debugPrint("###Warning### Trash folder not found")
                return
            }
            dataService.saveTrashFolder(path: path)
        }
    }

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
