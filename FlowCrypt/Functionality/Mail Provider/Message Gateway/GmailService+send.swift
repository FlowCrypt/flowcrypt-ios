//
//  GmailService+send.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST_Gmail

extension GmailService: MessageGateway, DraftSaveGateway {
    func sendMail(input: MessageGatewayInput, progressHandler: ((Float) -> Void)?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let raw = GTLREncodeBase64(input.mime) else {
                continuation.resume(throwing: GmailServiceError.messageEncode)
                return
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
                    continuation.resume(throwing: GmailServiceError.providerError(error))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func saveDraft(input: MessageGatewayInput, draft: GTLRGmail_Draft?) async throws -> GTLRGmail_Draft {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GTLRGmail_Draft, Error>) in
            guard let raw = GTLREncodeBase64(input.mime) else {
                continuation.resume(throwing: GmailServiceError.messageEncode)
                return
            }
            let draftQuery = createQueryForDraftAction(
                raw: raw,
                threadId: input.threadId,
                draft: draft)

            gmailService.executeQuery(draftQuery) { _, object, error in
                if let error = error {
                    continuation.resume(throwing: GmailServiceError.providerError(error))
                } else if let draft = object as? GTLRGmail_Draft {
                    continuation.resume(returning: (draft))
                } else {
                    continuation.resume(throwing: GmailServiceError.failedToParseData(nil))
                }
            }
        }
    }

    private func createQueryForDraftAction(raw: String, threadId: String?, draft: GTLRGmail_Draft?) -> GTLRGmailQuery {
        guard
            let createdDraft = draft,
            let draftIdentifier = createdDraft.identifier
        else {
            // draft is not created yet. creating draft
            let newDraft = GTLRGmail_Draft()
            let gtlMessage = GTLRGmail_Message()
            gtlMessage.raw = raw
            gtlMessage.threadId = threadId
            newDraft.message = gtlMessage

            return GTLRGmailQuery_UsersDraftsCreate.query(
                withObject: newDraft,
                userId: "me",
                uploadParameters: nil)
        }

        // updating existing draft with new data
        let gtlMessage = GTLRGmail_Message()
        gtlMessage.raw = raw
        gtlMessage.threadId = threadId
        createdDraft.message = gtlMessage

        return GTLRGmailQuery_UsersDraftsUpdate.query(
            withObject: createdDraft,
            userId: "me",
            identifier: draftIdentifier,
            uploadParameters: nil)
    }
}
