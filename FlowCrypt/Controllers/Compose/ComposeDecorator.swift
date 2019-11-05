//
//  ComposeDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 05.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

struct ComposeDecorator {
    func styledTextViewInput(with height: CGFloat) -> TextViewCellNode.Input {
        return TextViewCellNode.Input(
            placeholder: "message_compose_secure".localized.attributed(.regular(17), color: .lightGray, alignment: .left),
            prefferedHeight: height
        )
    }

    var styledTextFieldInput: (String) -> TextFieldCellNode.Input {
        return {
            TextFieldCellNode.Input(
                placeholder: $0.localized.attributed(.regular(17), color: .lightGray, alignment: .left),
                isSecureTextEntry: false,
                textInsets: -7,
                textAlignment: .left,
                height: 40
            )
        }
    }

    var styledTitle: (String) -> (NSAttributedString) {
        return { string in
            string.attributed(.regular(17))
        }
    }
}
