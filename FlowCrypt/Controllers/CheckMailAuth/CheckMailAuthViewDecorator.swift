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
        case setup, invalidGrant(String)

        var title: String {
            switch self {
            case .setup:
                return "setup_title".localized
            case .invalidGrant:
                return "error_connection".localized
            }
        }

        var message: String {
            switch self {
            case .setup:
                return "gmail_service_no_access_to_account_message".localized
            case let .invalidGrant(email):
                return "gmail_service_invalid_grant_error_message".localizeWithArguments(email)
            }
        }

        var numberOfRows: Int {
            switch self {
            case .setup:
                return 3
            case .invalidGrant:
                return 4
            }
        }
    }

    let type: CheckMailAuthType

    var title: NSAttributedString {
        type
            .title
            .attributed(
                .bold(35),
                color: .mainTextColor,
                alignment: .center
            )
    }
}
