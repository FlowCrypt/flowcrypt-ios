//
//  SetupButtonType.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

enum SetupButtonType {
    case loadAccount, createKey

    var title: String {
        switch self {
        case .loadAccount: return "setup_load".localized
        case .createKey: return "setup_create_key".localized
        }
    }

    var attributedTitle: NSAttributedString {
        title.attributed(.regular(17), color: .white, alignment: .center)
    }
}
