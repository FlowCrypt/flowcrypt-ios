//
//  Imap+Message.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

extension Imap: MessageProvider {
    func fetchMsg(message: Message, folder: String) -> Promise<Data> {
        Promise { [weak self] resolve, reject in
            guard let self = self else {
                return reject(AppErr.nilSelf)
            }

            guard let id = message.identifier.intId else {
                assertionFailure()
                return reject(AppErr.unexpected("Missed message identifier"))
            }

            self.imapSess?
                .fetchMessageOperation(withFolder: folder, uid: UInt32(id))
                .start(self.finalize("fetchMsg", resolve, reject, retry: { self.fetchMsg(message: message, folder: folder) }))
        }
    }
}
