//
//  CheckMailAuthViewDecorator.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 11/04/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

struct CheckMailAuthViewDecorator {
    enum CheckMailAuthType {
        case setup, invalidGrant

        var title: String {
            switch self {
            case .setup:
                return "setup_title".localized
            case .invalidGrant:
                return "setup_title".localized // todo
            }
        }

        var description: String {
            switch self {
            case .setup:
                return "gmail_service_no_access_to_account_message".localized
            case .invalidGrant:
                return "gmail_service_invalid_grant_error_message".localized
            }
        }
    }

    let type: CheckMailAuthType

    var title: NSAttributedString {
        type.title.attributed(
            .bold(35),
            color: .mainTextColor,
            alignment: .center
        )
    }
}
