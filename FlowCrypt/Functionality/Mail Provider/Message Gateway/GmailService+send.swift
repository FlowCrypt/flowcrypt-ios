//
//  GmailService+send.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST_Gmail

extension GmailService: MessageGateway {
    func sendMail(input: MessageGatewayInput) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let raw = GTLREncodeBase64(input.mime) else {
                continuation.resume(throwing: GmailServiceError.messageEncode)
                return
            }

            let gtlMessage = GTLRGmail_Message()
            gtlMessage.raw = raw
            gtlMessage.threadId = input.threadId

            let querySend = GTLRGmailQuery_UsersMessagesSend.query(
                withObject: gtlMessage,
                userId: "me",
                uploadParameters: nil
            )

            gmailService.executeQuery(querySend) { _, _, error in
                if let error = error {
                    continuation.resume(throwing: GmailServiceError.providerError(error))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
