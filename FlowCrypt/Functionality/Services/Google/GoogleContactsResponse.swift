//
//  GoogleContactsResponse.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 28/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

// swiftlint:disable nesting
struct GoogleContactsResponse: Decodable {
    let emails: [String]

    private enum CodingKeys: String, CodingKey {
        case feed

        enum Entry: String, CodingKey {
            case entry

            enum AdressKeys: String, CodingKey {
                case email = "gd$email"

                enum EmailKeys: String, CodingKey {
                    case address
                }
            }
        }
    }

    init(from decoder: Decoder) throws {
        // top-level container
        let container = try decoder.container(keyedBy: CodingKeys.self)

        do {
            let feedContainer = try container.nestedContainer(keyedBy: CodingKeys.Entry.self, forKey: .feed)

            var entryContainer = try feedContainer.nestedUnkeyedContainer(forKey: .entry)

            var names = [String]()
            while !entryContainer.isAtEnd {
                let addressContainer = try entryContainer.nestedContainer(keyedBy: CodingKeys.Entry.AdressKeys.self)
                var emailContainer = try addressContainer.nestedUnkeyedContainer(forKey: .email)
                let resultContainer = try emailContainer.nestedContainer(keyedBy: CodingKeys.Entry.AdressKeys.EmailKeys.self)
                names.append(try resultContainer.decode(String.self, forKey: .address))
            }
            emails = names
        } catch {
            emails = []
        }
    }
}
