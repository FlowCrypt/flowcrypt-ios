//
//  Gmail+MessageExtension.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 01/09/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import GoogleAPIClientForREST_Gmail

extension Message {
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    init(gmailMessage: GTLRGmail_Message) throws {
        guard let payload = gmailMessage.payload else {
            throw GmailApiError.missingMessagePayload
        }

        guard let messageHeaders = payload.headers else {
            throw GmailApiError.missingMessageInfo("headers")
        }

        guard let internalDate = gmailMessage.internalDate as? Double else {
            throw GmailApiError.missingMessageInfo("date")
        }

        guard let identifier = gmailMessage.identifier else {
            throw GmailApiError.missingMessageInfo("id")
        }

        let attachmentsIds = payload.parts?.compactMap { $0.body?.attachmentId } ?? []
        let labels: [MessageLabel] = gmailMessage.labelIds?.map(MessageLabel.init) ?? []
        let body = gmailMessage.parseMessageBody()
        var attachments = gmailMessage.parseAttachments()

        if body.hasNoContent, let bodyPartAttachment = gmailMessage.parseBodyPartAttachment() {
            attachments.append(bodyPartAttachment)
        }

        var sender: Recipient?
        var subject: String?
        var to: String?
        var cc: String?
        var bcc: String?
        var replyTo: String?
        var inReplyTo: String?
        var rfc822MsgId: String?
        var isSuspicious = false

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
            case .receivedSPF: isSuspicious = value.contains("softfail")
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
            inReplyTo: inReplyTo,
            isSuspicious: isSuspicious
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
        payload?.parts?.filter(\.filename.isEmptyOrNil) ?? []
    }

    func parseMessageBody() -> MessageBody {
        let html = body(type: .textHtml)
        var text = body(type: .textPlain) ?? html ?? ""
        if text.isHTMLString {
            text = text.removingHtmlTags()
        }
        let bodyAttachment = text.isEmpty ? parseBodyAttachment() : nil
        return MessageBody(text: text, html: html, attachment: bodyAttachment)
    }

    func parseBodyAttachment() -> MessageAttachment? {
        guard let part = payload?.body,
              let attachmentId = part.attachmentId
        else { return nil }

        return MessageAttachment(
            id: Identifier(stringId: attachmentId),
            name: "body",
            estimatedSize: part.size?.intValue,
            mimeType: "text/plain"
        )
    }

    func body(type: MessageBodyType) -> String? {
        guard let base64String = findBase64Body(type: type)?.data else { return nil }
        return GTLRDecodeWebSafeBase64(base64String)?.toStr()
    }

    private func findBase64Body(type: MessageBodyType) -> GTLRGmail_MessagePartBody? {
        if let body = textParts.findMessageBody(type: type)?.body {
            return body
        } else if let multipartBody = textParts.findMultipartBody(),
                  let body = multipartBody.parts?.findMessageBody(type: type)?.body {
            return body
        } else if let body = payload?.body {
            return body
        }

        return nil
    }

    func parseAttachments() -> [MessageAttachment] {
        (payload?.parts ?? []).compactMap {
            guard let body = $0.body, let id = body.attachmentId
            else { return nil }

            return MessageAttachment(
                id: Identifier(stringId: id),
                name: $0.filename ?? "noname",
                estimatedSize: body.size?.intValue,
                mimeType: $0.mimeType,
                data: body.data?.data()
            )
        }
    }

    func parseBodyPartAttachment() -> MessageAttachment? {
        guard let body = payload?.parts?.first(where: { $0.mimeType == "text/plain" })?.body,
              let attachmentId = body.attachmentId
        else { return nil }

        return MessageAttachment(
            id: Identifier(stringId: attachmentId),
            name: "encrypted.asc",
            estimatedSize: body.size?.intValue,
            mimeType: "text/plain"
        )
    }
}

private extension [GTLRGmail_MessagePart] {
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
