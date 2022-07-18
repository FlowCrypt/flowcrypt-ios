//
//  WKDURLsConstructor.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 15.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import CryptoKit
import Foundation

/// WKD - Web Key Directory, follow this link for more information https://wiki.gnupg.org/WKD

enum WkdMethod {
    case direct
    case advanced
}

struct WkdUrls {
    let policy: String
    let pubKeys: String
    let method: WkdMethod
}

protocol WkdUrlConstructorType {
    func construct(from email: String, method: WkdMethod) -> WkdUrls?
}

class WkdUrlConstructor: WkdUrlConstructorType {

    func construct(from email: String, method: WkdMethod) -> WkdUrls? {
        let parts = email.split(separator: "@")
        guard parts.count == 2 else {
            return nil
        }
        let user = String(parts[0])
        let domain = Bundle.shouldUseMockAttesterApi
            ? GeneralConstants.Mock.backendUrl.replacingOccurrences(of: "https://", with: "")
            : String(parts[1]).lowercased()
        let hu = String(decoding: user.lowercased().data().SHA1.zBase32EncodedBytes(), as: Unicode.UTF8.self)
        let userPart = "hu/\(hu)?l=\(user)"
        let base = method == .direct
            ? "https://\(domain)/.well-known/openpgpkey/"
            : "https://openpgpkey.\(domain)/.well-known/openpgpkey/\(domain)/"
        return WkdUrls(policy: "\(base)policy", pubKeys: "\(base)\(userPart)", method: method)
    }
}
