//
//  MessageOperationsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.12.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

protocol MessageOperationsProvider {
    func markAsRead()
}

extension Imap {
    func markAsRead(message: Message, folder: String) -> Promise<Void> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            guard let id = message.identifier.intId else {
                return reject(ImapError.missedMessageInfo("intId"))
            }

            var flags: MCOMessageFlag = []
            let imapFlagValues = message.labels.map(\.type.imapFlagValue)
            for value in imapFlagValues {
                flags.insert(MCOMessageFlag(rawValue: value))
            }

            self.imapSess?
                .storeFlagsOperation(
                    withFolder: folder,
                    uids: MCOIndexSet(index: UInt64(id)),
                    kind: MCOIMAPStoreFlagsRequestKind.add,
                    flags: flags
                )
                .start(self.finalizeVoid("markAsRead", resolve, reject, retry: { self.markAsRead(message: message, folder: folder) }))
        }
    }
}

import GTMSessionFetcher
import GoogleAPIClientForREST

extension GmailService {
//    func fetchMsg(message: Message, folder: String) -> Promise<Data> {
//        return Promise { (resolve, reject) in
//            guard let id = message.identifier.stringId else {
//                return reject(GmailServiceError.missedMessageInfo("id"))
//            }
//
//            let a = GTLRGmail_ModifyMessageRequest()
//
////            GTLRGmailQuery_UsersThreadsModify.query(withObject: , userId: <#T##String#>, identifier: <#T##String#>)
//
//            let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: .me, identifier: id)
//            query.format = kGTLRGmailFormatRaw
//
//            self.gmailService.executeQuery(query) { (_, data, error) in
//                if let error = error {
//                    reject(AppErr.providerError(error))
//                }
//                guard let gmailMessage = data as? GTLRGmail_Message else {
//                    return reject(AppErr.cast("GTLRGmail_Message"))
//                }
//                guard let raw = gmailMessage.raw else {
//                    return reject(GmailServiceError.missedMessageInfo("raw"))
//                }
//
//                guard let data = GTLRDecodeWebSafeBase64(raw) else {
//                    return reject(GmailServiceError.missedMessageInfo("data"))
//                }
//                resolve(data)
//            }
//        }
//    }
}
