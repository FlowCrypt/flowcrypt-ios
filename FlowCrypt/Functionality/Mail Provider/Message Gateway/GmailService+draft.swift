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
    func saveDraft(input: MessageGatewayInput, draft: GTLRGmail_Draft?) async throws -> GTLRGmail_Draft {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GTLRGmail_Draft, Error>) in
            guard let raw = GTLREncodeBase64(input.mime) else {
                return continuation.resume(throwing: GmailServiceError.messageEncode)
            }

            let draftQuery = createQueryForDraftAction(
                raw: raw,
                threadId: input.threadId,
                draft: draft
            )

            gmailService.executeQuery(draftQuery) { _, object, error in
                if let error = error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                } else if let draft = object as? GTLRGmail_Draft {
                    return continuation.resume(returning: (draft))
                } else {
                    return continuation.resume(throwing: GmailServiceError.failedToParseData(nil))
                }
            }
        }
    }

    func deleteDraft(with identifier: String) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let query = GTLRGmailQuery_UsersDraftsDelete.query(withUserId: .me, identifier: identifier)
            gmailService.executeQuery(query) { _, _, _ in
                return continuation.resume()
            }
        }
    }

    private func createQueryForDraftAction(raw: String, threadId: String?, draft: GTLRGmail_Draft?) -> GTLRGmailQuery {
        guard
            let existingDraft = draft,
            let draftIdentifier = existingDraft.identifier
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
                uploadParameters: nil
            )
        }

        // updating existing draft with new data
        let gtlMessage = GTLRGmail_Message()
        gtlMessage.raw = raw
        gtlMessage.threadId = threadId
        existingDraft.message = gtlMessage

        return GTLRGmailQuery_UsersDraftsUpdate.query(
            withObject: existingDraft,
            userId: "me",
            identifier: draftIdentifier,
            uploadParameters: nil
        )
    }
}
