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

    func data() -> Data {
        data(using: .utf8)!
    }

    func separate(
        every stride: Int = 4,
        with separator: Character = " "
    ) -> String {
        String(
            self.enumerated()
                .map { $0 > 0 && $0 % stride == 0 ? [separator, $1] : [$1]}
                .joined()
        )
    }
}

public extension NSAttributedString {
    static func + (_ lhs: NSAttributedString, _ rhs: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: lhs)
        mutable.append(rhs)
        return mutable
    }
}

public extension Optional where Wrapped == String {
    var nilIfEmpty: String? {
        guard let strongSelf = self else {
            return nil
        }
        return strongSelf.isEmpty ? nil : strongSelf
    }
}
