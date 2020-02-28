//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

public extension Data {
    func decodeJson<T>(as _: T.Type) throws -> T where T: Decodable {
        try JSONDecoder().decode(T.self, from: self)
    }

    static func joined(_ dataArray: [Data]) -> Data {
        var data = Data()
        for d in dataArray {
            data += d
        }
        return data
    }

    func toStr() -> String {
        String(decoding: self, as: UTF8.self)
    }
}
