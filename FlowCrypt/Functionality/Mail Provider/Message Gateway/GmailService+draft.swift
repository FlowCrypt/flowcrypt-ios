//
//  GmailService+draft.swift
//  FlowCrypt
//
//  Created by Evgenii Kyivskyi on 10/22/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
import Foundation
import GoogleAPIClientForREST_Gmail

extension GmailService: DraftGateway {
    func fetchDraftId(messageId: String) async throws -> String? {
        let query = GTLRGmailQuery_UsersDraftsList.query(withUserId: .me)
        query.q = "rfc822msgid:\(messageId)"
        query.maxResults = 1

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String?, Error>) in
            gmailService.executeQuery(query) { _, data, error in
                if let error = error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }

                guard let list = data as? GTLRGmail_ListDraftsResponse else {
                    return continuation.resume(throwing: AppErr.cast("GTLRGmail_ListDraftsResponse"))
                }

                let draftId = list.drafts?.first?.identifier
                return continuation.resume(returning: draftId)
            }
        }
    }

    func saveDraft(input: MessageGatewayInput, draftId: String?) async throws -> GTLRGmail_Draft {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GTLRGmail_Draft, Error>) in
            guard let raw = GTLREncodeBase64(input.mime) else {
                return continuation.resume(throwing: GmailServiceError.messageEncode)
            }

            let draftQuery = createQueryForDraftAction(
                raw: raw,
                threadId: input.threadId,
                draftId: draftId
            )

            gmailService.executeQuery(draftQuery) { _, object, error in
                if let error = error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                } else if let draft = object as? GTLRGmail_Draft {
                    return continuation.resume(returning: draft)
                } else {
                    return continuation.resume(throwing: GmailServiceError.failedToParseData(nil))
                }
            }
        }
    }

    func deleteDraft(with identifier: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let query = GTLRGmailQuery_UsersDraftsDelete.query(withUserId: .me, identifier: identifier)
            gmailService.executeQuery(query) { _, _, error in
                if let error = error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }
                return continuation.resume()
            }
        }
    }

    private func createQueryForDraftAction(raw: String, threadId: String?, draftId: String?) -> GTLRGmailQuery {
        let draft = GTLRGmail_Draft()

        let message = GTLRGmail_Message()
        message.raw = raw
        message.threadId = threadId

        draft.message = message

        if let draftId = draftId {
            draft.identifier = draftId

            return GTLRGmailQuery_UsersDraftsUpdate.query(
                withObject: draft,
                userId: "me",
                identifier: draftId,
                uploadParameters: nil
            )
        } else {
            return GTLRGmailQuery_UsersDraftsCreate.query(
                withObject: draft,
                userId: "me",
                uploadParameters: nil
            )
        }
    }
}
