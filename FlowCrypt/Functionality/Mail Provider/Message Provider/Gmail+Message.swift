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

    func fetchMsg(id: Identifier,
                  folder: String,
                  progressHandler: ((MessageFetchState) -> Void)?) async throws -> Message {
        guard let identifier = id.stringId else {
            throw GmailServiceError.missingMessageInfo("id")
        }

        let query = createMessageQuery(identifier: identifier, format: kGTLRGmailFormatFull)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Message, Error>) in
            self.gmailService.executeQuery(query) { _, data, error in
                if let error = error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }

                guard let gmailMessage = data as? GTLRGmail_Message else {
                    return continuation.resume(throwing: AppErr.cast("GTLRGmail_Message"))
                }

                progressHandler?(.decrypt)

                do {
                    let message = try Message(gmailMessage)
                    return continuation.resume(returning: message)
                } catch {
                    return continuation.resume(throwing: error)
                }
            }
        }
    }

    private func fetchMessageSize(identifier: String) async throws -> Float {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Float, Error>) in
            let query = createMessageQuery(identifier: identifier, format: kGTLRGmailFormatFull)
            query.fields = "payload.parts, sizeEstimate"
            self.gmailService.executeQuery(query) { _, data, error in
                if let error = error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }

                guard let gmailMessage = data as? GTLRGmail_Message else {
                    return continuation.resume(throwing: AppErr.cast("GTLRGmail_Message"))
                }

                // check if encrypted
                // if not - render email

                guard let sizeEstimate = gmailMessage.sizeEstimate?.floatValue else {
                    return continuation.resume(throwing: GmailServiceError.missingMessageInfo("sizeEstimate"))
                }

                // google returns smaller estimated size
                let totalSize = sizeEstimate * Float(1.3)
                return continuation.resume(with: .success(totalSize))
            }
        }
    }

    private func createMessageFetcher(identifier: String) -> GTMSessionFetcher {
        let query = createMessageQuery(identifier: identifier, format: kGTLRGmailFormatFull)
        let request = gmailService.request(for: query) as URLRequest
        return gmailService.fetcherService.fetcher(with: request)
    }

    private func createMessageQuery(identifier: String, format: String) -> GTLRGmailQuery_UsersMessagesGet {
        let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: .me, identifier: identifier)
        query.format = format
        return query
    }
}

extension GTLRGmail_Message {
    var isEncrypted: Bool {
        if let plainText = body(type: .text), plainText.starts(with: "-----BEGIN PGP MESSAGE-----") {
            return true
        }
        return false
    }

    var textParts: [GTLRGmail_MessagePart] {
        payload?.parts?.filter { $0.filename.isEmptyOrNil } ?? []
    }

    var attachmentParts: [GTLRGmail_MessagePart] {
        payload?.parts?.filter { !$0.filename.isEmptyOrNil } ?? []
    }

    func header(name: String) -> String? {
        payload?.headers?.first(where: { $0.name == name })?.value
    }

    func body(type: MessageBodyType) -> String? {
        if let text = textParts.first(where: { $0.mimeType == type.rawValue })?.body?.data {
            return text.base64Decoded
        } else if let text = textParts.first(where: { $0.mimeType == "multipart/alternative" })?.parts?.first(where: { $0.mimeType == type.rawValue })?.body?.data {
            return text.base64Decoded
        } else {
            return nil
        }
    }
}

enum MessageBodyType: String {
    case text = "text/plain", html = "text/html"
}
