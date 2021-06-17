//
//  FilesManagerTests.swift
//  FlowCryptTests
//
//  Created by Yevhen Kyivskyi on 17.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import XCTest

class FilesManagerTests: XCTestCase {
    
    var filesManager: FilesManagerType!

    override func setUp() {
        filesManager = FilesManager()
    }

    override func tearDown() {
        filesManager = nil
    }

    func test_save_file() {
        var isFileSaved = false
        let file = FileMock.stringedFile
        let expectation = XCTestExpectation()
        
        filesManager.save(file: file)
            .then { _ in
                isFileSaved = true
                expectation.fulfill()
            }
        
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pathComponent = url.appendingPathComponent(file.name)
        let filePath = pathComponent.path
        
        wait(for: [expectation], timeout: 2)
        
        XCTAssertTrue(
            isFileSaved, "filesManager.save should call then block if file succesfully saved"
        )
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: filePath), "file should exist in documents directory"
        )
    }
}
