//
//  Document.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 19.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

final class Document: UIDocument {
    var data: Data?

    override func contents(forType typeName: String) throws -> Any {
        guard let data = data else { return Data() }
        return try NSKeyedArchiver.archivedData(
            withRootObject:data,
            requiringSecureCoding: true
        )
    }

    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let data = contents as? Data else { return }
        self.data = data
    }
}
