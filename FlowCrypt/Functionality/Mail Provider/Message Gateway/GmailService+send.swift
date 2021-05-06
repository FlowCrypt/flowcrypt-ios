//
//  GmailService+send.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST
import GTMSessionFetcher
import Combine

extension GmailService: MessageGateway {
    func sendMail(mime: Data) -> Future<Void, Error> {
        Future { promise in
            guard let raw = GTLREncodeBase64(mime) else {
                promise(.failure(GmailServiceError.messageEncode))
                return
            }

            let gtlMessage = GTLRGmail_Message()
            gtlMessage.raw = raw

            let querySend = GTLRGmailQuery_UsersMessagesSend.query(
                withObject: gtlMessage,
                userId: "me",
                uploadParameters: nil
            )

            self.gmailService.executeQuery(querySend) { (_, _, error) in
                if let error = error {
                    promise(.failure(GmailServiceError.providerError(error)))
                    return
                }
                promise(.success(()))
            }
        }
    }
}
