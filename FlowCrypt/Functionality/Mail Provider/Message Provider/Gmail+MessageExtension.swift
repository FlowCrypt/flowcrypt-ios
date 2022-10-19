//
//  Gmail+MessageExtension.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 01/09/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import GoogleAPIClientForREST_Gmail

extension Message {
    init(gmailMessage: GTLRGmail_Message) throws {
        guard let payload = gmailMessage.payload else {
            throw GmailServiceError.missingMessagePayload
        }

        guard let messageHeaders = payload.headers else {
            throw GmailServiceError.missingMessageInfo("headers")
        }

        guard let internalDate = gmailMessage.internalDate as? Double else {
            throw GmailServiceError.missingMessageInfo("date")
        }

        guard let identifier = gmailMessage.identifier else {
            throw GmailServiceError.missingMessageInfo("id")
        }

        let attachmentsIds = payload.parts?.compactMap { $0.body?.attachmentId } ?? []
        let labels: [MessageLabel] = gmailMessage.labelIds?.map(MessageLabel.init) ?? []
        let body = gmailMessage.parseMessageBody()
        let attachments = gmailMessage.parseAttachments()

        var sender: Recipient?
        var subject: String?
        var to: String?
        var cc: String?
        var bcc: String?
        var replyTo: String?
        var inReplyTo: String?
        var rfc822MsgId: String?

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
            case .identifier: rfc822MsgId = value
            default: break
            }
        }

        self.init(
            identifier: Identifier(stringId: identifier),
            // convert miliseconds to seconds
            date: Date(timeIntervalSince1970: internalDate / 1000),
            sender: sender,
            subject: subject,
            size: gmailMessage.sizeEstimate.flatMap(Int.init),
            labels: labels,
            attachmentIds: attachmentsIds,
            body: body,
            attachments: attachments,
            threadId: gmailMessage.threadId,
            rfc822MsgId: rfc822MsgId,
            raw: gmailMessage.raw,
            to: to,
            cc: cc,
            bcc: bcc,
            replyTo: replyTo,
            inReplyTo: inReplyTo
        )
    }
}

private enum MessageBodyType: String {
    case textPlain = "text/plain",
         textHtml = "text/html",
         multipartAlternative = "multipart/alternative",
         multipartMixed = "multipart/mixed"
}

private extension GTLRGmail_Message {
    var textParts: [GTLRGmail_MessagePart] {
        payload?.parts?.filter { $0.filename.isEmptyOrNil } ?? []
    }

    var attachmentParts: [GTLRGmail_MessagePart] {
        payload?.parts?.filter { !$0.filename.isEmptyOrNil } ?? []
    }

    func parseMessageBody() -> MessageBody {
        let html = body(type: .textHtml)
        let text = body(type: .textPlain) ?? html?.removingHtmlTags() ?? ""
        return MessageBody(text: text, html: html)
    }

    func body(type: MessageBodyType) -> String? {
        guard let base64String = findBase64Body(type: type) else { return nil }
        return GTLRDecodeWebSafeBase64(base64String)?.toStr()
    }

    private func findBase64Body(type: MessageBodyType) -> String? {
        if let text = textParts.findMessageBody(type: type)?.body?.data {
            return text
        } else if let multipartBody = textParts.findMultipartBody(),
                  let text = multipartBody.parts?.findMessageBody(type: type)?.body?.data {
            return text
        } else if let body = payload?.body?.data {
            return body
        }

        return nil
    }

    func parseAttachments() -> [MessageAttachment] {
        attachmentParts.compactMap {
            guard let body = $0.body, let id = body.attachmentId, let name = $0.filename
            else { return nil }

            return MessageAttachment(
                id: Identifier(stringId: id),
                name: name,
                estimatedSize: body.size?.intValue,
                mimeType: $0.mimeType,
                data: body.data?.data()
            )
        }
    }
}

private extension Array where Iterator.Element == GTLRGmail_MessagePart {
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
