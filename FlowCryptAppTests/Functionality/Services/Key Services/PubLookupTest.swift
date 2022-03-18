//
//  PubLookupTest.swift
//  FlowCrypt
//
//  Created by Tom on 27/10/2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class PubLookupTest: XCTestCase {

    func lookupFromAttesterWithDifferentPgpUidAllowed() async throws {
        // tests https://github.com/FlowCrypt/flowcrypt-ios/issues/809
        // fetches https://flowcrypt.com/attester/pub/different.uid@recipient.test
        // if this test starts failing, ensure the right pubkey is still on prod Attester
        let pubLookup = PubLookup(
            clientConfiguration: ClientConfiguration(
                raw: RawClientConfiguration()
            ),
            localContactsProvider: LocalContactsProviderMock()
        )
        let r = try await pubLookup.lookup(email: "different.uid@recipient.test")
        XCTAssertTrue(r.pubKeys.isNotEmpty, "expected pubkeys not empty")
        XCTAssertEqual(r.pubKeys.first?.longid, "0C9C2E6A4D273C6F")
    }
}
