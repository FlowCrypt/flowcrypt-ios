//
//  GoogleContactsResponse.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 28/02/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct GoogleContactsResponse: Decodable {
    let results: [PersonResult]?

    struct PersonResult: Decodable {
        let person: Person

        struct Person: Decodable {
            let emailAddresses: [EmailAddress]

            struct EmailAddress: Decodable {
                let value: String
            }
        }
    }
}

extension GoogleContactsResponse {
    var emails: [String] {
        results?
            .map(\.person)
            .flatMap(\.emailAddresses)
            .map { String($0.value) }
            ?? []
    }
}
