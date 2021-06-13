//
//  WKDURLsConstructor.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 15.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import CryptoKit
import Foundation

/// WKD - Web Key Directory, follow this link for more information https://wiki.gnupg.org/WKD

enum WKDURLMode {
    case direct
    case advanced
}

struct WKDURLsConstructorResult {
    let urlString: String
    let userPart: String
}

protocol WKDURLsConstructorType {
    func construct(from email: String, mode: WKDURLMode) -> WKDURLsConstructorResult?
}

class WKDURLsConstructor: WKDURLsConstructorType {

    func construct(from email: String, mode: WKDURLMode) -> WKDURLsConstructorResult? {
        let parts = email.split(separator: "@")
        if parts.count != 2 {
            return nil
        }
        let user = String(parts[0])
        let recipientDomain = String(parts[1]).lowercased()
        let hu = String(decoding: user.lowercased().data().SHA1.zBase32EncodedBytes(), as: Unicode.UTF8.self)
        let userPart = "hu/\(hu)?l=\(user)"
        let directURL = "https://\(recipientDomain)/.well-known/openpgpkey/hu/\(hu)?l=\(user)"
        let advancedURL = "https://openpgpkey.\(recipientDomain)/.well-known/openpgpkey/\(recipientDomain)/hu/\(hu)?l=\(user)"

        return mode == .advanced
            ? WKDURLsConstructorResult(urlString: advancedURL, userPart: userPart)
            : WKDURLsConstructorResult(urlString: directURL, userPart: userPart)
    }
}
