//
//  GmailSearchExpressionGeneratorTests.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 17.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import XCTest
@testable import FlowCrypt

class GmailSearchExpressionGeneratorTests: XCTestCase {
    
    var sut: GmailSearchExpressionGenerator!
    
    override func setUp() {
        sut = GmailSearchExpressionGenerator()
    }
    
    func testBackupExpressions() {
        let expressions = GeneralConstants.EmailConstant.recoverAccountSearchSubject
        let result = sut.makeBackupQuery(with: expressions)
        
        XCTAssertTrue(result.contains("in:anywhere !!!"))
        XCTAssertTrue(result.contains("\"Your FlowCrypt Backup\""))
        XCTAssertTrue(result.contains("\"Your CryptUp Backup\""))
        XCTAssertTrue(result.contains("\"CryptUP Account Backup\""))
        XCTAssertTrue(result.contains("\"All you need to know about CryptUP (contains a backup)\""))
        XCTAssertTrue(result.contains(" has:attachment"))
    }
}
