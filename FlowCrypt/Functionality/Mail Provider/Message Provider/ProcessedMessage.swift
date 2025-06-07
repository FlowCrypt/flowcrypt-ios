//
//  ProcessedMessage.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 17/01/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import SwiftSoup
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
        self.type = type
        self.attachments = attachments
        self.keyDetails = keyDetails
        self.signature = signature
    }

    init(message: Message, keyDetails: [KeyDetails] = []) async throws {
        self.message = message
        self.type = .plain
        if let html = message.body.html {
            let (text, quote) = Self.parseHtmlQuote(from: html)
            self.text = try await Core.shared.sanitizeHtml(html: text)
            if let quote {
                // SanitizeHtml replaces > with &gt; so need to convert it back
                self.quote = try await (Core.shared.sanitizeHtml(html: quote)).replacingOccurrences(of: "&gt;", with: ">")
            } else {
                self.quote = nil
            }
        } else {
            (self.text, self.quote) = Self.parseQuote(text: message.body.text)
        }
        self.attachments = message.attachments
        self.signature = .unsigned
        self.keyDetails = keyDetails
    }
}

extension ProcessedMessage {
    private static func parsePlainHtmlQuote(from html: String) -> (String, String?) {
        // This pattern accounts for:
        // - 1 or 2 occurrences of \r\n or \n before "On"
        // - "On ... wrote:" across multiple lines
        // - 1 or 2 occurrences of \r\n or \n after "wrote:"
        //
        // Explanation of groups:
        //   (?:\r?\n){1,2}   : "either \n or \r\n" repeated 1 or 2 times, non-capturing group
        //   [\s\S]+?         : any characters, non-greedy
        //   dotMatchesLineSeparators so "." can include newlines
        //
        let pattern = #"(?:\r?\n){1,2}On[\s\S]+?wrote:(?:\r?\n){1,2}"#
        // Allow . to match across line breaks, case-insensitive
        let options: NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]

        guard let markerRegex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return (html, nil)
        }

        let fullRange = NSRange(location: 0, length: html.utf16.count)
        // Find first match of the above pattern
        guard let match = markerRegex.firstMatch(in: html, options: [], range: fullRange) else {
            // No match -> everything is main content
            return (html, nil)
        }

        // MAIN CONTENT is everything before the matched pattern
        let mainRange = NSRange(location: 0, length: match.range.location)
        guard let swiftMainRange = Range(mainRange, in: html) else {
            return (html, nil)
        }
        let mainContent = String(html[swiftMainRange])

        // QUOTED CONTENT is everything from the match onward
        let quoteRange = NSRange(location: match.range.location, length: html.utf16.count - match.range.location)
        guard let swiftQuoteRange = Range(quoteRange, in: html) else {
            return (mainContent, nil)
        }
        let quotedContent = String(html[swiftQuoteRange])

        return (mainContent, quotedContent)
    }

    private static func parseHtmlQuote(from html: String) -> (String, String?) {
        do {
            let doc = try SwiftSoup.parse(html)
            let quotes = try doc.select("div.gmail_quote")

            // Assuming the first div.gmail_quote is the start of the quoted section
            if let firstQuote = quotes.first() {
                try firstQuote.remove() // Remove the quote from the document
                let mainContent = try doc.body()?.html() ?? ""
                let quoteContent = try firstQuote.outerHtml()
                return (mainContent, quoteContent)
            }
            // Try to extract quote from text which is written in gmail plain mode
            // https://github.com/FlowCrypt/flowcrypt-ios/issues/2656
            return Self.parsePlainHtmlQuote(from: html)
        } catch {
            Logger.nested("ProceessedMessage").logError("Failed to parse HTML with SwiftSoup: \(error.localizedDescription)")
        }
        return (html, nil)
    }

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

    var attributedMessage: NSAttributedString {
        String(text.prefix(maxLength)).attributed(color: type.textColor)
    }

    var attributedQuote: NSAttributedString? {
        guard let quote else { return nil }
        return String(quote.prefix(maxLength)).attributed(color: type.textColor.withAlphaComponent(0.8))
    }
}
