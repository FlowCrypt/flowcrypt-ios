//
//  Gmail+Message.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import GoogleAPIClientForREST_Gmail
import Promises

extension GmailService: MessageProvider {
    func fetchMsg(message: Message, folder: String) -> Promise<Data> {
        Promise { resolve, reject in
            guard let identifier = message.identifier.stringId else {
                return reject(GmailServiceError.missedMessageInfo("id"))
            }

            let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: .me, identifier: identifier)
            query.format = kGTLRGmailFormatRaw

            self.gmailService.executeQuery(query) { _, data, error in
                if let error = error {
                    reject(GmailServiceError.providerError(error))
                    return
                }
                guard let gmailMessage = data as? GTLRGmail_Message else {
                    return reject(AppErr.cast("GTLRGmail_Message"))
                }
                guard let raw = gmailMessage.raw else {
                    return reject(GmailServiceError.missedMessageInfo("raw"))
                }

                guard let data = GTLRDecodeWebSafeBase64(raw) else {
                    return reject(GmailServiceError.missedMessageInfo("data"))
                }
                resolve(data)
            }
        }
    }
}
