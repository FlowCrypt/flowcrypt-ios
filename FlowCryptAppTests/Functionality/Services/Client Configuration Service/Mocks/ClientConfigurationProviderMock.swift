//
//  LocalClientConfigurationMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 21.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt

class LocalClientConfigurationMock: LocalClientConfigurationType {
    var raw: RawClientConfiguration?

    var fetchInvoked = false
    var fetchCount = 0

    func load(for user: String) -> RawClientConfiguration? {
        fetchInvoked = true
        fetchCount += 1
        return raw
    }

    var removeClientConfigurationInvoked = false
    var removeClientConfigurationCount = 0
    func remove(for user: String) {
        raw = nil
        removeClientConfigurationInvoked = true
        removeClientConfigurationCount += 1
    }

    var saveInvoked = false
    var saveCount = 0
    var saveCall: (RawClientConfiguration) -> Void = { clientConfiguration in
    }

    func save(for user: String, raw: RawClientConfiguration, fesUrl: String?) {
        self.raw = raw
        saveInvoked = true
        saveCount += 1
        saveCall(raw)
    }
}
