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

    private func createMessageQuery(identifier: String, format: String) -> GTLRGmailQuery_UsersMessagesGet {
        let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: .me, identifier: identifier)
        query.format = format
        return query
    }
}

extension GTLRGmail_Message {
    var textParts: [GTLRGmail_MessagePart] {
        payload?.parts?.filter { $0.filename.isEmptyOrNil } ?? []
    }

    var attachmentParts: [GTLRGmail_MessagePart] {
        payload?.parts?.filter { !$0.filename.isEmptyOrNil } ?? []
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
