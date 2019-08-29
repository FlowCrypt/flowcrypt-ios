//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

@available(*, deprecated, message: "Use FCError")

enum Errors: Error {
    case programmingError(String)
    case valueError(String)
}
