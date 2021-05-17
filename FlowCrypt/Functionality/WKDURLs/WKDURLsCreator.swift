//
//  WKDURLsConstructor.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 15.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

/// WKD - Web Key Directory, follow this link for more information https://wiki.gnupg.org/WKD

enum WKDURLMode {
    case direct
    case advanced
}

protocol WKDURLsConstructorType {
    func construct(from email: String, mode: WKDURLMode) -> String?
}

class WKDURLsConstructor: WKDURLsConstructorType {

    func construct(from email: String, mode: WKDURLMode) -> String? {

        let parts = email.split(separator: "@")
        if parts.count != 2 {
            return nil
        }
        let user = parts[0]
        let recipientDomain = parts[1]

        let hu = String(user).data().zBase32EncodedString()

        let advancedURL = "https://openpgpkey.\(recipientDomain).well-known/openpgpkey/\(recipientDomain)/hu/\(hu)?l=\(user)"
        let directURL = "https://\(recipientDomain)/.well-known/openpgpkey/hu/\(hu)?l=\(user)"

        return mode == .advanced ? advancedURL : directURL
    }
}
