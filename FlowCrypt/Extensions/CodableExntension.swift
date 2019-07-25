//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

extension Encodable {

    func toJsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }

    func toDict() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }

}
