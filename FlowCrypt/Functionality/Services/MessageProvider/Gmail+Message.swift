//
//  Gmail+Message.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Promises
import GTMSessionFetcher
import GoogleAPIClientForREST

extension GmailService: MessageProvider {
    func fetchMsg(message: Message, folder: String) -> Promise<Data> {
        return Promise { (resolve, reject) in
            guard let id = message.identifier.stringId else {
                return reject(GmailServiceError.missedMessageInfo("id"))
            }

            let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: .me, identifier: id)
            query.format = kGTLRGmailFormatRaw

            self.gmailService.executeQuery(query) { (_, data, error) in
                if let error = error {
                    reject(AppErr.providerError(error))
                }
                guard let gmailMessage = data as? GTLRGmail_Message else {
                    return reject(AppErr.cast("GTLRGmail_Message"))
                }
                guard let raw = gmailMessage.raw else {
                    return reject(GmailServiceError.missedMessageInfo("raw"))
                }

                guard let data = GTLRDecodeBase64(raw) else {
                    return reject(GmailServiceError.missedMessageInfo("data"))
                }

                resolve(GTLRDecodeWebSafeBase64(raw)!)

//                resolve(data)
            }
        }
    }
}
