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
    func styledTextFieldInput(with text: String) -> TextFieldCellNode.Input
    func styledRecipientInfo(with email: String) -> InfoCellNode.Input
    func styledTitle(with text:String?) -> NSAttributedString?
}

struct ComposeDecorator: ComposeDecoratorType {
    func styledTextViewInput(with height: CGFloat) -> TextViewCellNode.Input {
        TextViewCellNode.Input(
            placeholder: "message_compose_secure".localized.attributed(
                .regular(17),
                color: .lightGray,
                alignment: .left
            ),
            preferredHeight: height
        )
    }

    func styledTextFieldInput(with text: String) -> TextFieldCellNode.Input {
        TextFieldCellNode.Input(
            placeholder: text.localized.attributed(
                .regular(17),
                color: .lightGray,
                alignment: .left
            ),
            isSecureTextEntry: false,
            textInsets: -8,
            textAlignment: .left,
            height: 40,
            width: UIScreen.main.bounds.width
        )
    }

    func styledTitle(with text:String?) -> NSAttributedString? {
        guard let text = text else { return nil }
        return text.attributed(.regular(17))
    }

    func styledRecipientInfo(with email: String) -> InfoCellNode.Input {
        InfoCellNode.Input(
            attributedText: email.attributed(
                .medium(17),
                color: UIColor.black.withAlphaComponent(0.8),
                alignment: .left
            ),
            image: nil,
            insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        )
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
