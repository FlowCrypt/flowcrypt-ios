//
//  SignInType.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit

enum SignInType: String {
    case gmail, outlook, other

    var title: String {
        switch self {
        case .gmail: return "sign_in_gmail".localized
        case .outlook: return "sign_in_outlook".localized
        case .other: return "sign_in_other".localized
        }
    }

    var image: UIImage? {
        switch self {
        case .gmail: return UIImage(named: "gmail_icn")
        case .outlook: return UIImage(named: "microsoft-outlook")
        case .other: return UIImage(named: "email_icn")
        }
    }

    var attributedTitle: NSAttributedString {
        NSAttributedString.text(from: title, style: .medium(17), color: .mainTextColor)
    }
}
