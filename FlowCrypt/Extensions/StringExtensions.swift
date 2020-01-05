//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

extension String {
    var hasContent: Bool {
        return trimmingCharacters(in: .whitespaces).isEmpty == false
    }

    var trimLeadingSlash: String {
        if count > 0, self[self.startIndex] == "/" {
            return String(dropFirst())
        }
        return self
    }

    func data() -> Data {
        return data(using: .utf8)!
    }
}

extension NSAttributedString {
    static func +(_ lhs: NSAttributedString, _ rhs: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: lhs)
        mutable.append(rhs)
        return mutable
    }
}
