//
//  ComposeDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 05.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import FlowCryptUI

protocol ComposeDecoratorType {
    func styledTextViewInput(with height: CGFloat) -> TextViewCellNode.Input
    var styledTextFieldInput: (String) -> TextFieldCellNode.Input { get }
    var styledTitle: (String?) -> (NSAttributedString?) { get }
}

struct ComposeDecorator: ComposeDecoratorType {
    func styledTextViewInput(with height: CGFloat) -> TextViewCellNode.Input {
        TextViewCellNode.Input(
            placeholder: "message_compose_secure".localized.attributed(.regular(17), color: .lightGray, alignment: .left),
            preferredHeight: height
        )
    }

    var styledTextFieldInput: (String) -> TextFieldCellNode.Input {
        {
            TextFieldCellNode.Input(
                placeholder: $0.localized.attributed(.regular(17), color: .lightGray, alignment: .left),
                isSecureTextEntry: false,
                textInsets: -8,
                textAlignment: .left,
                height: 40,
                width: UIScreen.main.bounds.width
            )
        }
    }

    var styledTitle: (String?) -> (NSAttributedString?) {
        { string in
            guard let string = string else { return nil }
            return string.attributed(.regular(17))
        }
    }
}

extension RecipientEmailsCellNode.Input {
    init(_ recipient: ComposeViewController.Recipient) {
        self.init(
            email: recipient.email.lowercased().attributed(.regular(17), color: .black, alignment: .left),
            isSelected: recipient.isSelected
        )
    }
}
