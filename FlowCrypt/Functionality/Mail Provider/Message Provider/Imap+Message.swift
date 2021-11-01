//
//  Imap+Message.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises

extension Imap: MessageProvider {
    func fetchMsg(message: Message,
                  folder: String,
                  progressHandler: ((MessageFetchState) -> Void)?) -> Promise<Data> {
        Promise { [weak self] resolve, reject in
            guard let self = self else {
                return reject(AppErr.nilSelf)
            }

            guard let identifier = message.identifier.intId else {
                assertionFailure()
                return reject(AppErr.unexpected("Missed message identifier"))
            }

            let retry = { self.fetchMsg(message: message, folder: folder, progressHandler: progressHandler) }
            self.imapSess?
                .fetchMessageOperation(withFolder: folder, uid: UInt32(identifier))
                .start(self.finalize("fetchMsg", resolve, reject, retry: retry))
        }
    }
}
