//
//  SignInButton.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

enum SignInType: String {
    case gmail, outlook

    var title: String {
        switch self {
        case .gmail: return "sign_in_gmail".localized
        case .outlook: return "sign_in_outlook".localized
        }
    }

    var image: UIImage? {
        switch self {
        case .gmail: return UIImage(named: "gmail_icn")
        case .outlook: return UIImage(named: "outlook_icn")
        }
    } 

    var attributedTitle: NSAttributedString {
        return NSAttributedString.text(from: title, style: .medium(17), color: .black)
    }
}
