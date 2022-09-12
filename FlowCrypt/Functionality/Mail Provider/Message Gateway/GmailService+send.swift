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
    func sendMail(input: MessageGatewayInput, progressHandler: ((Float) -> Void)?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let raw = GTLREncodeBase64(input.mime) else {
                return continuation.resume(throwing: GmailServiceError.messageEncode)
            }

            self.progressHandler = progressHandler

            let gtlMessage = GTLRGmail_Message()
            gtlMessage.raw = raw
            gtlMessage.threadId = input.threadId

            let querySend = GTLRGmailQuery_UsersMessagesSend.query(
                withObject: gtlMessage,
                userId: "me",
                uploadParameters: nil
            )

            gmailService.executeQuery(querySend) { [weak self] _, _, error in
                self?.progressHandler = nil
                if let error = error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }
                return continuation.resume()
            }
        }
    }
}
