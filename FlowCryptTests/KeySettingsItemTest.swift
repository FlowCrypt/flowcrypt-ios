//
//  KeySettingsItemTest.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import XCTest

class KeySettingsItemTest: XCTestCase {
    func test_key_initializer() {
        let keyId1 = KeyId(
            shortid: "short",
            longid: "long",
            fingerprint: "print",
            keywords: "Tesla"
        )
        let keyId2 = KeyId(
            shortid: "short id",
            longid: "long id",
            fingerprint: "print twice",
            keywords: "iOS"
        )
        let keyDetails = KeyDetails(
            public: "some public",
            private: "some private",
            isFullyDecrypted: true,
            isFullyEncrypted: true,
            ids: [keyId1, keyId2],
            created: 12312312,
            users: ["ilon@tesla.com", "donald@trump"]
        )
        
        let keySettingsItem = KeySettingsItem(keyDetails)
        let date = Date(timeIntervalSince1970: TimeInterval(keyDetails.created))
        XCTAssert(keySettingsItem?.title == "some private")
        XCTAssert(keySettingsItem?.createdDate == date)
        XCTAssert(keySettingsItem?.details == keyDetails.ids)
        XCTAssert(keySettingsItem?.publicKey == "some public")
        XCTAssert(keySettingsItem?.users == "ilon@tesla.com donald@trump ")
    }
}
