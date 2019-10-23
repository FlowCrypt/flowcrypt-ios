//
//  OptionsButton.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 22.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

enum SignInOption: String, CaseIterable {
    case privacy, terms, security

    var title: String {
        switch self {
        case .privacy: return "sign_in_privacy".localized
        case .terms: return "sign_in_terms".localized
        case .security: return "sign_in_security".localized
        }
    }

    var attributedTitle: NSAttributedString {
        return NSAttributedString.text(from: title, style: .medium(17), color: .textColor)
    }

    var url: URL? {
        switch self {
        case .privacy: return URL(string: "https://flowcrypt.com/privacy")
        case .terms: return URL(string: "https://flowcrypt.com/license")
        case .security: return URL(string: "https://flowcrypt.com/docs/technical/security.html")
        }
    }
}
