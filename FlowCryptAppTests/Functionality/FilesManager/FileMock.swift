//
//  FileMock.swift
//  FlowCryptTests
//
//  Created by Yevhen Kyivskyi on 17.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct FileMock: FileType {
    let name: String
    let data: Data
}

extension FileMock {
    static let stringedFile = FileMock(
        name: "mock_file.pdf",
        data: "mocktext".data(using: .utf8)!
    )
}
