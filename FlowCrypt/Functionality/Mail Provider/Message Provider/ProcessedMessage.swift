//
//  ProcessedMessage.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 17/01/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

struct ProcessedMessage {
    enum MessageType: Hashable {
        case error(DecryptErr.ErrorType), encrypted, plain

        var textColor: UIColor {
            switch self {
            case .encrypted:
                return .main
            case .error:
                return .errorColor
            case .plain:
                return .mainTextColor
            }
        }
    }

    enum MessageSignature: Hashable {
        case good, goodMixed, unsigned, error(String), missingPubkey(String), partial, bad, pending

        func message(email: String) -> String {
            switch self {
            case .good:
                return "message_signed".localized
            case .goodMixed:
                return "message_signature_good_mixed".localized
            case .unsigned:
                return "message_not_signed".localized
            case let .error(message):
                let signatureErrorString = "message_signature_verify_error".localized
                return signatureErrorString + GeneralConstants.Global.signatureSeparator + message.lowercasingFirstLetter()
            case let .missingPubkey(longid):
                let missingPubKeyString = "message_missing_pubkey".localizeWithArguments(longid.spaced(every: 4), email)
                let signatureErrorString = "message_signature_verify_error".localized
                return signatureErrorString + GeneralConstants.Global.signatureSeparator + missingPubKeyString
            case .partial:
                return "message_signature_partial".localized
            case .bad:
                return "message_bad_signature".localized
            case .pending:
                return "message_signature_pending".localized
            }
        }

        var icon: String {
            switch self {
            case .good, .goodMixed:
                return "lock"
            case .error, .missingPubkey, .partial:
                return "exclamationmark.triangle"
            case .unsigned, .bad:
                return "xmark"
            case .pending:
                return "clock"
            }
        }

        var color: UIColor {
            switch self {
            case .good, .goodMixed:
                return .main
            case .error, .missingPubkey, .partial:
                return .warningColor
            case .unsigned, .bad:
                return .errorColor
            case .pending:
                return .lightGray
            }
        }
    }

    private let maxLength = 1_000_000

    let message: Message
    var text: String
    let quote: String?
    let type: MessageType
    // Couldn't use getter because when we tried to convert html to nsattributedstring in getter, it takes forever
    let attributedMessage: NSAttributedString?
    var attachments: [MessageAttachment]
    var keyDetails: [KeyDetails] = []
    var signature: MessageSignature?
}

extension ProcessedMessage {
    init(
        message: Message,
        text: String,
        type: MessageType,
        attachments: [MessageAttachment] = [],
        keyDetails: [KeyDetails] = [],
        signature: MessageSignature? = nil
    ) {
        self.message = message
        (self.text, self.quote) = Self.parseQuote(text: text)
        attributedMessage = String(text.prefix(maxLength)).convertToNSAttributedString(color: type.textColor)
        self.type = type
        self.attachments = attachments
        self.keyDetails = keyDetails
        self.signature = signature
    }

    init(message: Message, keyDetails: [KeyDetails] = []) async throws {
        self.message = message
        var body = message.body.text
        if let html = message.body.html {
            body = try await Core.shared.sanitizeHtml(html: html)
        }
        (self.text, self.quote) = Self.parseQuote(text: body)
        self.type = .plain
        attributedMessage = String(text.prefix(maxLength)).convertToNSAttributedString(color: type.textColor)
        self.attachments = message.attachments
        self.signature = .unsigned
        self.keyDetails = keyDetails
    }
}

extension ProcessedMessage {
    private static func parseQuote(text: String) -> (String, String?) {
        var lines = text.components(separatedBy: .newlines)
        var quoteLines: [String] = []
        while !lines.isEmpty {
            guard let lastLine = lines.popLast() else { break }

            let trimmedLine = lastLine.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty || trimmedLine.hasPrefix(">") {
                quoteLines.insert(lastLine, at: 0)
            } else {
                if trimmedLine.hasPrefix("On "), trimmedLine.hasSuffix(" wrote:") {
                    quoteLines.insert(lastLine, at: 0)
                } else {
                    lines.append(lastLine)
                }
                break
            }
        }
        let hasQuote = quoteLines.contains { !$0.isEmpty }
        let quote = hasQuote ? quoteLines.joined(separator: "\n") : nil
        let message = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return (message, quote)
    }

    var fullText: String {
        [text, quote].compactMap { $0 }.joined(separator: "\n")
    }

//
//    var attributedMessage: NSAttributedString {
//        String(text.prefix(maxLength)).attributed(color: type.textColor)
//    }

    var attributedQuote: NSAttributedString? {
        guard let quote else { return nil }
        return String(quote.prefix(maxLength)).attributed(color: type.textColor.withAlphaComponent(0.8))
    }
}
