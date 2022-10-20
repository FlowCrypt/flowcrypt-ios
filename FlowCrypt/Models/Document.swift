//
//  Document.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 19.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

final class Document: UIDocument {
    var data: Data?

    override func contents(forType _: String) throws -> Any {
        guard let data else { return Data() }
        return try NSKeyedArchiver.archivedData(
            withRootObject: data,
            requiringSecureCoding: true
        )
    }

    override func load(fromContents contents: Any, ofType _: String?) throws {
        guard let data = contents as? Data else { return }
        self.data = data
    }
}
