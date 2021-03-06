//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

public extension Sequence {
    // same as .map { $0 } except will also run closure on each item
    // useful for debugging maps/filters/etc:
    //      .map { $0.hello }
    //      .also { print("All: \($0)") }
    //      .filter { !$0.isEmpty }
    //      .also { print("Filtered: \($0)")}
    @inlinable func also(_ doThis: (Element) -> Void) -> [Element] {
        return map {
            doThis($0)
            return $0
        }
    }
}
