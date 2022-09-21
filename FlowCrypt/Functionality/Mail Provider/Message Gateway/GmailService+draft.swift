//
//  GmailService+draft.swift
//  FlowCrypt
//
//  Created by Evgenii Kyivskyi on 10/22/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import GoogleAPIClientForREST_Gmail

extension GmailService: DraftGateway {
    func fetchMessage(draftIdentifier: Identifier) async throws -> Message? {
        guard let id = draftIdentifier.stringId else { return nil }

        let query = GTLRGmailQuery_UsersDraftsGet.query(withUserId: .me, identifier: id)
        query.format = kGTLRGmailFormatFull

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Message, Error>) in
            gmailService.executeQuery(query) { _, data, error in
                if let error = error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }

                guard let draft = data as? GTLRGmail_Draft else {
                    return continuation.resume(throwing: AppErr.cast("GTLRGmail_Draft"))
                }

                guard let gmailMessage = draft.message else {
                    return continuation.resume(throwing: AppErr.cast("GTLRGmail_Draft"))
                }

                do {
                    let message = try Message(gmailMessage: gmailMessage)
                    return continuation.resume(returning: message)
                } catch {
                    return continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchDraft(for messageId: Identifier) async throws -> MessageDraft? {
        guard let id = messageId.stringId else { return nil }

        let query = GTLRGmailQuery_UsersDraftsList.query(withUserId: .me)
        query.q = "rfc822msgid:\(id)"
        query.maxResults = 1

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MessageDraft?, Error>) in
            gmailService.executeQuery(query) { _, data, error in
                if let error = error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }

                guard let list = data as? GTLRGmail_ListDraftsResponse else {
                    return continuation.resume(throwing: AppErr.cast("GTLRGmail_ListDraftsResponse"))
                }

                guard let gmailDraft = list.drafts?.first else {
                    return continuation.resume(returning: nil)
                }
                let draft = MessageDraft(gmailDraft: gmailDraft)
                return continuation.resume(returning: draft)
            }
        }
    }

    func saveDraft(input: MessageGatewayInput, draftId: Identifier?) async throws -> MessageDraft {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MessageDraft, Error>) in
            guard let raw = GTLREncodeBase64(input.mime) else {
                return continuation.resume(throwing: GmailServiceError.messageEncode)
            }

            let draftQuery = createQueryForDraftAction(
                raw: raw,
                threadId: input.threadId,
                draftId: draftId?.stringId
            )

            gmailService.executeQuery(draftQuery) { _, object, error in
                if let error = error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                } else if let gmailDraft = object as? GTLRGmail_Draft {
                    let draft = MessageDraft(gmailDraft: gmailDraft)
                    return continuation.resume(returning: draft)
                } else {
                    return continuation.resume(throwing: GmailServiceError.failedToParseData(nil))
                }
            }
        }
    }

    func deleteDraft(with identifier: Identifier) async throws {
        guard let id = identifier.stringId else { return }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let query = GTLRGmailQuery_UsersDraftsDelete.query(withUserId: .me, identifier: id)
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
