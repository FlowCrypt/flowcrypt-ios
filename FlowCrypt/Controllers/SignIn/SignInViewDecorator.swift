//
//  SignInViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/03/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import FlowCryptUI
import UIKit

protocol SignInViewDecoratorType {
    var description: NSAttributedString { get }
    var logo: UIImage? { get }
}

struct SignInViewDecorator: SignInViewDecoratorType {
    var description: NSAttributedString {
        "sign_in_description"
            .localized
            .attributed(
                .medium(15),
                color: UIColor.colorFor(darkStyle: .mainTextColor, lightStyle: .textColor),
                alignment: .center
            )
    }

    var logo: UIImage? {
        UIImage(named: "full-logo")
    }
}

extension SigninButtonNode {
    convenience init(_ buttonType: UserSignInType, onTap: (() -> Void)?) {
        self.init(
            input: SigninButtonNode.Input(buttonType),
            onTap: onTap
        )
    }
}

extension SigninButtonNode.Input {
    init(_ signInType: UserSignInType) {
        self.init(title: signInType.attributedTitle, image: signInType.image)
    }
}

enum UserSignInType {
    case gmail, outlook, other

    private var title: String {
        switch self {
        case .gmail: return "sign_in_gmail".localized
        case .outlook: return "sign_in_outlook".localized
        case .other: return "sign_in_other".localized
        }
    }

    fileprivate var image: UIImage? {
        switch self {
        case .gmail: return UIImage(named: "gmail_icn")
        case .outlook: return UIImage(named: "microsoft-outlook")
        case .other: return UIImage(named: "email_icn")?.tinted(.mainTextColor)
        }
    }

    fileprivate var attributedTitle: NSAttributedString {
        NSAttributedString.text(from: title, style: .medium(17), color: .mainTextColor)
    }
}

extension SignInViewController.AppLinks: Link {
    var title: String {
        switch self {
        case .privacy: return "sign_in_privacy".localized
        case .terms: return "sign_in_terms".localized
        case .security: return "sign_in_security".localized
        }
    }

    var attributedTitle: NSAttributedString {
        NSAttributedString.text(from: title, style: .medium(17), color: .mainTextColor)
    }

    var url: URL? {
        switch self {
        case .privacy: return URL(string: "https://flowcrypt.com/privacy")
        case .terms: return URL(string: "https://flowcrypt.com/license")
        case .security: return URL(string: "https://flowcrypt.com/docs/technical/security.html")
        }
    }
}
