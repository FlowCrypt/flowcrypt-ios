//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

struct VOID {
    // Promise has an issue with certain Void return situations, likely caused by Promises written in Swift 4 while we use Swift 5
    // cannot infer types & dunno how to fix that cleanly, so using this value to indicate that the promise doesn't return anything
}
