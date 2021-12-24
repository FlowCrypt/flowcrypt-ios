//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

public extension String {
    var hasContent: Bool {
        trimmingCharacters(in: .whitespaces).isEmpty == false
    }

    var trimLeadingSlash: String {
        if count > 0, self[startIndex] == "/" {
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
                .map { $0 > 0 && $0 % stride == 0 ? [separator, $1] : [$1] }
                .joined()
        )
    }

    func slice(from: String, to: String) -> String? {
        (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
    
    var deletingPathExtension: String {
        return NSString(string: self).deletingPathExtension as String
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
    var emailParts: (username: String, domain: String)? {
        let parts = self.split(separator: "@")
        guard parts.count == 2 else { return nil }
        return (String(parts[0]), String(parts[1]))
    }
}
