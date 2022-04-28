//
//  FileMock.swift
//  FlowCryptTests
//
//  Created by Yevhen Kyivskyi on 17.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

extension FileItem {
    static let stringedFile = FileItem(
        name: "mock_file.pdf",
        data: "mocktext".data(using: .utf8)!
    )
}
