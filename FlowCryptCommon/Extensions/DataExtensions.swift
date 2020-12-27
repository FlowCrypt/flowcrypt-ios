//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

public extension Data {
    func decodeJson<T>(as _: T.Type) throws -> T where T: Decodable {
        try JSONDecoder().decode(T.self, from: self)
    }

    func toStr() -> String {
        String(decoding: self, as: UTF8.self)
    }
}

extension String {
    init(data: Data) {
        self = String(decoding: data, as: UTF8.self)
    }
}

public extension Array where Element == Data {
    var joined: Data {
        reduce(Data(), +)
    }
}
