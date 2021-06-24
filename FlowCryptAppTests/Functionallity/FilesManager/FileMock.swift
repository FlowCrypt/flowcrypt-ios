//
//  FileMock.swift
//  FlowCryptTests
//
//  Created by Yevhen Kyivskyi on 17.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct FileMock: FileType {
    let name: String
    let size: Int
    let data: Data
}

extension FileMock {
    static let stringedFile = FileMock(
        name: "mock_file.pdf",
        size: 125,
        data: "mocktext".data(using: .utf8)!
    )
}
