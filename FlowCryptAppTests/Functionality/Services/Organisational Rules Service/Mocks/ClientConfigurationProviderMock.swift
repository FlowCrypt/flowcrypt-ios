//
//  ClientConfigurationProviderMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 21.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
@testable import FlowCrypt

class ClientConfigurationProviderMock: ClientConfigurationProviderType {
    var fetchInvoked = false
    var fetchCount = 0
    var fetchCall: () -> (ClientConfiguration?) = {
        nil
    }
    func fetch() -> ClientConfiguration? {
        fetchInvoked = true
        fetchCount += 1
        return fetchCall()
    }

    var removeClientConfigurationInvoked = false
    var removeClientConfigurationCount = 0
    func removeClientConfiguration() {
        removeClientConfigurationInvoked = true
        removeClientConfigurationCount += 1
    }

    var saveInvoked = false
    var saveCount = 0
    var saveCall: (ClientConfiguration) -> (Void) = { clientConfiguration in

    }
    func save(clientConfiguration: ClientConfiguration) {
        saveInvoked = true
        saveCount += 1
        saveCall(clientConfiguration)
    }
}
