//
//  SignInViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit
import FlowCryptUI
import FlowCryptCommon

protocol SignInViewDecoratorType {
    var description: NSAttributedString { get }
    var logo: UIImage? { get }
}

struct SignInViewDecorator: SignInViewDecoratorType {
    var description: NSAttributedString {
        "sign_in_description"
            .localized
            .attributed(
                .medium(13),
                color: UIColor.colorFor(darkStyle: .mainTextColor, lightStyle: .textColor),
                alignment: .center
        )
    }
    
    var logo: UIImage? {
        UIImage(named: "full-logo")
    }
}

extension SigninButtonNode {
    convenience init(_ buttonType: SignInType, onTap: (() -> Void)?) {
        self.init(
            input: SigninButtonNode.Input.init(buttonType),
            onTap: onTap
        )
        button.accessibilityLabel = buttonType.rawValue
    }
}

extension SigninButtonNode.Input {
    init(_ signInType: SignInType) {
        self.init(title: signInType.attributedTitle, image: signInType.image)
    }
}

extension AppLinks: Link {
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
