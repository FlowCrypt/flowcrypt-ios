//
//  GmailService+send.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Combine
import Foundation
import GoogleAPIClientForREST_Gmail

extension GmailService: MessageGateway {
    func sendMail(mime: Data) -> Future<Void, Error> {
        Future { promise in
            guard let raw = GTLREncodeBase64(mime) else {
                return promise(.failure(GmailServiceError.messageEncode))
            }

            let gtlMessage = GTLRGmail_Message()
            gtlMessage.raw = raw

            let querySend = GTLRGmailQuery_UsersMessagesSend.query(
                withObject: gtlMessage,
                userId: "me",
                uploadParameters: nil
            )

            self.gmailService.executeQuery(querySend) { _, _, error in
                if let error = error {
                    return promise(.failure(GmailServiceError.providerError(error)))
                }
                promise(.success(()))
            }
        }
    }
}
