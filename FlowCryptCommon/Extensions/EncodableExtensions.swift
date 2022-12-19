//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

public extension Encodable {
    func toJsonData() throws -> Data {
        try JSONEncoder().encode(self)
    }
}
