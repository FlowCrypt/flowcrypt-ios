//
//  EnterpriseServerApiMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 21.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt

final class EnterpriseServerApiMock: EnterpriseServerApiType {
    var email = "example@flowcrypt.test"
    var fesUrl: String?

    var getActiveFesUrlInvoked = false
    var getActiveFesUrlInvokedCount = 0
    var getActiveFesUrlCall: (String) -> String? = { _ in
        return nil
    }

    func getActiveFesUrl(for email: String) async throws -> String? {
        getActiveFesUrlInvoked = true
        getActiveFesUrlInvokedCount += 1
        return getActiveFesUrlCall(email)
    }

    var getActiveFesUrlForCurrentUserInvoked = false
    var getActiveFesUrlForCurrentUserCount = 0
    var getActiveFesUrlForCurrentUserCall: () throws -> String = {
        throw OrganisationalRulesServiceError.getActiveFesUrlForCurrentUserCall
    }

    func getActiveFesUrlForCurrentUser() async throws -> String? {
        getActiveFesUrlForCurrentUserInvoked = true
        getActiveFesUrlForCurrentUserCount += 1
        return try getActiveFesUrlForCurrentUserCall()
    }

    var getClientConfigurationInvoked = false
    var getClientConfigurationCount = 0
    var getClientConfigurationCall: (String) throws -> RawClientConfiguration = { _ in
        throw OrganisationalRulesServiceError.getClientConfigurationCall
    }

    func getClientConfiguration() async throws -> RawClientConfiguration {
        getClientConfigurationInvoked = true
        getClientConfigurationCount += 1
        return try getClientConfigurationCall(email)
    }

    var getClientConfigurationForCurrentUserInvoked = false
    var getClientConfigurationForCurrentUserCount = 0
    var getClientConfigurationForCurrentUserCall: () throws -> RawClientConfiguration = {
        throw OrganisationalRulesServiceError.getClientConfigurationForCurrentUserCall
    }

    func getClientConfigurationForCurrentUser() async throws -> RawClientConfiguration {
        getClientConfigurationForCurrentUserInvoked = true
        getClientConfigurationForCurrentUserCount += 1
        return try getClientConfigurationForCurrentUserCall()
    }

    func getReplyToken() async throws -> String {
        return ""
    }

    func upload(message: Data, details: MessageUploadDetails, progressHandler: ((Float) -> Void)?) async throws -> String {
        return ""
    }
}
