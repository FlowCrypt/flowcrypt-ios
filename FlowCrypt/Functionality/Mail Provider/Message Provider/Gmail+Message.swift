//
//  Gmail+Message.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import GoogleAPIClientForREST_Gmail
import GTMSessionFetcherCore

extension GmailService: MessageProvider {

    func fetchMessage(
        id: Identifier,
        folder: String
    ) async throws -> Message {
        guard let identifier = id.stringId else {
            throw GmailServiceError.missingMessageInfo("id")
        }

        let query = createMessageQuery(identifier: identifier, format: kGTLRGmailFormatFull)
        return try await withCheckedThrowingContinuation { continuation in
            self.gmailService.executeQuery(query) { _, data, error in
                if let error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }

                guard let gmailMessage = data as? GTLRGmail_Message else {
                    return continuation.resume(throwing: AppErr.cast("GTLRGmail_Message"))
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

    func fetchRawMessage(id: Identifier) async throws -> String {
        guard let identifier = id.stringId else {
            throw GmailServiceError.missingMessageInfo("id")
        }

        let query = createMessageQuery(identifier: identifier, format: kGTLRGmailFormatRaw)
        return try await withCheckedThrowingContinuation { continuation in
            self.gmailService.executeQuery(query) { _, data, error in
                if let error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }

                guard let gmailMessage = data as? GTLRGmail_Message else {
                    return continuation.resume(throwing: AppErr.cast("GTLRGmail_Message"))
                }

                guard let raw = gmailMessage.raw else {
                    return continuation.resume(throwing: GmailServiceError.missingMessageInfo("raw"))
                }

                guard let decoded = GTLRDecodeWebSafeBase64(raw)?.toStr() else {
                    return continuation.resume(throwing: GmailServiceError.missingMessageInfo("data"))
                }

                return continuation.resume(returning: decoded)
            }
        }
    }

    func fetchAttachment(
        id: Identifier,
        messageId: Identifier,
        estimatedSize: Float?,
        progressHandler: ((Float) -> Void)?
    ) async throws -> Data {
        guard let identifier = id.stringId else {
            throw GmailServiceError.missingMessageInfo("id")
        }
        guard let messageIdentifier = messageId.stringId else {
            throw GmailServiceError.missingMessageInfo("id")
        }

        let fetcher = createAttachmentFetcher(identifier: identifier, messageId: messageIdentifier)
        if let estimatedSize {
            fetcher.receivedProgressBlock = { _, received in
                let progress = min(Float(received) / estimatedSize, 1)
                progressHandler?(progress)
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            fetcher.beginFetch { data, error in
                if let error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }

                guard let data,
                      let dictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let attachmentBase64String = dictionary["data"] as? String
                else {
                    return continuation.resume(throwing: GmailServiceError.missingMessageInfo("data"))
                }

                guard let attachmentData = GTLRDecodeWebSafeBase64(attachmentBase64String) else {
                    return continuation.resume(throwing: GmailServiceError.messageEncode)
                }

                return continuation.resume(returning: attachmentData)
            }
        }
    }

    private func createAttachmentFetcher(identifier: String, messageId: String) -> GTMSessionFetcher {
        let query = createAttachmentQuery(identifier: identifier, messageId: messageId)
        let request = gmailService.request(for: query) as URLRequest
        return gmailService.fetcherService.fetcher(with: request)
    }

    private func createAttachmentQuery(identifier: String, messageId: String) -> GTLRGmailQuery_UsersMessagesAttachmentsGet {
        .query(
            withUserId: .me,
            messageId: messageId,
            identifier: identifier
        )
    }

    private func createMessageQuery(identifier: String, format: String) -> GTLRGmailQuery_UsersMessagesGet {
        let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: .me, identifier: identifier)
        query.format = format
        return query
    }
}
