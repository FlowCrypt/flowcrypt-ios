//
//  GmailService+send.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises
import GoogleAPIClientForREST
import GTMSessionFetcher

extension GmailService: MessageSender {
    func sendMail(mime: Data) -> Promise<Void> {
        Promise { (resolve, reject) in
            guard let raw = GTLREncodeBase64(mime) else {
                return reject(MessageSenderError.encode)
            }

            let gtlMessage = GTLRGmail_Message()
            gtlMessage.raw = raw

            let querySend = GTLRGmailQuery_UsersMessagesSend.query(
                withObject: gtlMessage,
                userId: "me",
                uploadParameters: nil
            )

            self.gmailService.executeQuery(querySend) { (ticket, any, error) in
                if let error = error {
                    reject(MessageSenderError.providerError(error))
                }
                resolve(())
            }
        }
    }
}
