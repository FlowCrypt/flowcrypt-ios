//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

public extension DispatchTime {
    var millisecondsSince: UInt64 {
        (DispatchTime.now().uptimeNanoseconds - uptimeNanoseconds) / 1_000_000
    }
}
