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

    func toDict() throws -> [String: Any] {
        try JSONSerialization.jsonObject(with: self, options: []) as? [String: Any] ?? [:]
    }
}

public extension NSMutableData {
    func append(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        self.append(data)
    }
}

extension String {
    init(data: Data) {
        self = String(decoding: data, as: UTF8.self)
    }
}

public extension [Data] {
    var joined: Data {
        reduce(Data(), +)
    }
}
