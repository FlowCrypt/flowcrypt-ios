//
//  ClientConfigurationServiceTest.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 10.09.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import XCTest
import Promises
@testable import FlowCrypt

// check if Email Key Manager should be used test and other client configuration is consistent
class ClientConfigurationServiceTest: XCTestCase {

    var sut: ClientConfigurationService!
    var organisationalRulesService = OrganisationalRulesServiceMock()

    override func setUp() {
        super.setUp()

        sut = ClientConfigurationService(organisationalRulesService: organisationalRulesService)
    }

    func testCheckDoesNotUseEKM() {
        // EKM should not be used if keyManagerUrl is nil
        organisationalRulesService.clientConfiguration = ClientConfiguration(keyManagerUrl: nil)
        XCTAssert(sut.checkShouldUseEKM() == .doesNotUseEKM)
    }

    func testShouldUseEKM() {
        organisationalRulesService.clientConfiguration = ClientConfiguration(
            flags: [
                .privateKeyAutoimportOrAutogen,
                .forbidStoringPassphrase
            ],
            keyManagerUrl: "https://test.ekm.flowcrypt.com"
        )

        XCTAssert(sut.checkShouldUseEKM() == .usesEKM)
    }

    func testCheckShouldUseEKMShouldFailWithWrongConfiguration() {

    }
}


class OrganisationalRulesServiceMock: OrganisationalRulesServiceType {

    var fetchOrganisationalRulesForCurrentUserResult: Result<OrganisationalRules, Error> = .failure(MockError.some)
    func fetchOrganisationalRulesForCurrentUser() -> Promise<OrganisationalRules> {
        .resolveAfter(timeout: 1, with: fetchOrganisationalRulesForCurrentUserResult)
    }

    var fetchOrganisationalRulesForEmail: (String) -> (Result<OrganisationalRules, Error>) = { email in
        return .failure(MockError.some)
    }
    func fetchOrganisationalRules(for email: String) -> Promise<OrganisationalRules> {
        .resolveAfter(timeout: 1, with: fetchOrganisationalRulesForEmail(email))
    }

    var clientConfiguration: ClientConfiguration!

    var getSavedOrganisationalRulesForCurrentUserResult: OrganisationalRules {
        OrganisationalRules(clientConfiguration: clientConfiguration)
    }
    func getSavedOrganisationalRulesForCurrentUser() -> OrganisationalRules {
        getSavedOrganisationalRulesForCurrentUserResult
    }
}
