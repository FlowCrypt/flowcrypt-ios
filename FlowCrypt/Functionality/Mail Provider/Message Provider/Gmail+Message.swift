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

    func fetchMsg(
        id: Identifier,
        folder: String
    ) async throws -> Message {
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

                do {
                    let message = try Message(gmailMessage)
                    return continuation.resume(returning: message)
                } catch {
                    return continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchRawMsg(id: Identifier) async throws -> String {
        guard let identifier = id.stringId else {
            throw GmailServiceError.missingMessageInfo("id")
        }

        let query = createMessageQuery(identifier: identifier, format: kGTLRGmailFormatRaw)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            self.gmailService.executeQuery(query) { _, data, error in
                if let error = error {
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
        if let estimatedSize = estimatedSize {
            fetcher.receivedProgressBlock = { _, received in
                let progress = min(Float(received)/estimatedSize, 1)
                progressHandler?(progress)
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            fetcher.beginFetch { data, error in
                if let error = error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }

                guard let data = data,
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

extension GTLRGmail_Message {
    var textParts: [GTLRGmail_MessagePart] {
        payload?.parts?.filter { $0.filename.isEmptyOrNil } ?? []
    }

    var attachmentParts: [GTLRGmail_MessagePart] {
        payload?.parts?.filter { !$0.filename.isEmptyOrNil } ?? []
    }

    func body(type: MessageBodyType) -> Data? {
        if let text = textParts.findMessageBody(type: type)?.body?.data {
            return GTLRDecodeWebSafeBase64(text)
        } else if let multipartBody = textParts.findMultipartBody(),
                  let text = multipartBody.parts?.findMessageBody(type: type)?.body?.data {
            return GTLRDecodeWebSafeBase64(text)
        } else if let body = payload?.body?.data {
            return GTLRDecodeWebSafeBase64(body)
        } else {
            return nil
        }
    }
}

enum MessageBodyType: String {
    case text = "text/plain",
         html = "text/html",
         multipartAlternative = "multipart/alternative",
         multipartMixed = "multipart/mixed"
}

extension Array where Iterator.Element == GTLRGmail_MessagePart {
    func findMultipartBody() -> GTLRGmail_MessagePart? {
        let types = [MessageBodyType.multipartMixed, MessageBodyType.multipartAlternative].map(\.rawValue)
        return first(where: {
            guard let mimeType = $0.mimeType else { return false }
            return types.contains(mimeType)
        })
    }

    func findMessageBody(type: MessageBodyType) -> GTLRGmail_MessagePart? {
        first(where: { $0.mimeType == type.rawValue })
    }
}

extension Message {
    init(
        _ message: GTLRGmail_Message,
        draftIdentifier: String? = nil
    ) throws {
        guard let payload = message.payload else {
            throw GmailServiceError.missingMessagePayload
        }

        guard let messageHeaders = payload.headers else {
            throw GmailServiceError.missingMessageInfo("headers")
        }

        guard let internalDate = message.internalDate as? Double else {
            throw GmailServiceError.missingMessageInfo("date")
        }

        guard let identifier = message.identifier else {
            throw GmailServiceError.missingMessageInfo("id")
        }

        let attachmentsIds = payload.parts?.compactMap { $0.body?.attachmentId } ?? []
        let labels: [MessageLabel] = message.labelIds?.map(MessageLabel.init) ?? []
        let bodyHtml = message.body(type: .html)?.toStr()
        let bodyText = message.body(type: .text)?.toStr() ?? bodyHtml?.htmlToString() ?? ""
        let body = MessageBody(text: bodyText, html: bodyHtml)
        let attachments: [MessageAttachment] = message.attachmentParts.compactMap {
            guard let body = $0.body, let id = body.attachmentId, let name = $0.filename
            else { return nil }
            return MessageAttachment(
                id: Identifier(stringId: id),
                name: name,
                estimatedSize: body.size?.intValue,
                mimeType: $0.mimeType,
                data: nil
            )
        }

        var sender: Recipient?
        var subject: String?
        var to: String?
        var cc: String?
        var bcc: String?
        var replyTo: String?
        var inReplyTo: String?

        for messageHeader in messageHeaders.compactMap({ $0 }) {
            guard let name = messageHeader.name?.lowercased(),
                  let value = messageHeader.value
            else { continue }

            switch name {
            case .from: sender = Recipient(value)
            case .subject: subject = value
            case .to: to = value
            case .cc: cc = value
            case .bcc: bcc = value
            case .replyTo: replyTo = value
            case .inReplyTo: inReplyTo = value
            default: break
            }
        }

        self.init(
            identifier: Identifier(stringId: identifier),
            // Should be divided by 1000, because Date(timeIntervalSince1970:) expects seconds
            // but GTLRGmail_Message.internalDate is in miliseconds
            date: Date(timeIntervalSince1970: internalDate / 1000),
            sender: sender,
            subject: subject,
            size: message.sizeEstimate.flatMap(Int.init),
            labels: labels,
            attachmentIds: attachmentsIds,
            body: body,
            attachments: attachments,
            threadId: message.threadId,
            draftIdentifier: draftIdentifier,
            raw: message.raw,
            to: to,
            cc: cc,
            bcc: bcc,
            replyTo: replyTo,
            inReplyTo: inReplyTo
        )
    }
}

extension String {
    func htmlToString() -> String? {
        return try? NSAttributedString(data: self.data(using: .utf8)!,
                                        options: [.documentType: NSAttributedString.DocumentType.html],
                                        documentAttributes: nil).string
    }
}
