//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

public extension String {
    var hasContent: Bool {
        !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isPgp: Bool {
        contains("-----BEGIN PGP ") && contains("-----END PGP ")
    }

    var trimLeadingSlash: String {
        if isNotEmpty, self[startIndex] == "/" {
            return String(dropFirst())
        }
        return self
    }

    var addTrailingSlashIfNeeded: String {
        if self.last != "/" {
            return "\(self)/"
        }
        return self
    }

    func data() -> Data {
        data(using: .utf8)!
    }

    func separate(
        every stride: Int = 4,
        with separator: Character = " "
    ) -> String {
        String(
            self.enumerated()
                .map { $0 > 0 && $0.isMultiple(of: stride) ? [separator, $1] : [$1] }
                .joined()
        )
    }

    func spaced(every n: Int) -> String {
        return enumerated().reduce("") {
            $0 + ($1.offset % n == 0 && $1.offset != 0 ? " " : "") + String($1.element)
        }
    }

    func slice(from: String, to: String) -> String? {
        (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom ..< endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom ..< substringTo])
            }
        }
    }

    var deletingPathExtension: String {
        NSString(string: self).deletingPathExtension as String
    }

    func capitalizingFirstLetter() -> String {
        prefix(1).uppercased() + self.lowercased().dropFirst()
    }

    func lowercasingFirstLetter() -> String {
        prefix(1).lowercased() + self.dropFirst()
    }

    var mailFolderIcon: String {
        switch self {
        case "INBOX":
            return "envelope"
        case "CHAT":
            return "message"
        case "SENT":
            return "paperplane"
        case "IMPORTANT", "":
            return "tag"
        case "TRASH":
            return "trash"
        case "DRAFT":
            return "square.and.pencil"
        case "SPAM":
            return "exclamationmark.shield"
        case "STARRED":
            return "star"
        case "UNREAD":
            return "envelope.badge"
        default:
            return "tag.fill"
        }
    }

    func removingHtmlTags() -> String? {
        try? NSAttributedString(
            data: self.data(using: .utf8)!,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        ).string
    }

    func isHTMLString() -> Bool {
        return self.range(of: "^\\s*(<!doctype html[\\s\\S]*>)?\\s*<[a-z][\\s\\S]*>\\s*$", options: [.regularExpression, .caseInsensitive]) != nil
    }

    func removingMailThreadQuote() -> String {
        guard let range = range(
            of: "On [a-zA-Z0-9, ]*, at [a-zA-Z0-9: ]*, .* wrote:",
            options: [.regularExpression]
        ) else { return self }

        return self[startIndex ..< range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public extension NSAttributedString {
    static func + (_ lhs: NSAttributedString, _ rhs: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: lhs)
        mutable.append(rhs)
        return mutable
    }
}

// MARK: Email parsing
public extension String {
    var isValidEmail: Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: self)
    }

    var emailParts: (username: String, domain: String)? {
        let parts = self.split(separator: "@")
        guard parts.count == 2 else { return nil }
        return (String(parts[0]), String(parts[1]))
    }
}
