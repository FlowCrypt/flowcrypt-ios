//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

extension Data {

    func decodeJson<T>(as type: T.Type) throws -> T where T : Decodable {
        return try JSONDecoder().decode(T.self, from: self)
    }

}
