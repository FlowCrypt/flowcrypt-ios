//
//  ComposeMessageServiceTests.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import XCTest
@testable import FlowCrypt

class ComposeMessageServiceTests: XCTestCase {

    var sut: ComposeMessageService!
    
    
    override func setUp() {
        super.setUp()
        
        sut = ComposeMessageService(
            messageGateway: MessageGatewayMock(),
            dataService: KeyStorageMock(),
            contactsService: ContactsServiceMock(),
            core: CoreComposeMessageMock()
        )
    }

}
