//
//  SetupPassPraseNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class SetupPassPraseNode: CellNode {
    typealias DidEndEditingCompletion = (String) -> Void
    private let textField = TextFieldNode()
    private var onDidEndEditing: DidEndEditingCompletion?

    init(_ placeholder: NSAttributedString = SetupStyle.passPrasePlaceholder, onDidEndEditing: DidEndEditingCompletion?) {
        super.init()
        self.onDidEndEditing = onDidEndEditing
        textField.attributedPlaceholderText = placeholder
        textField.delegate = self
        textField.isSecureTextEntry = true
        textField.textAlignment = .center
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16),
            child: textField
        )
    }
}

extension SetupPassPraseNode: UITextFieldDelegate {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        onDidEndEditing?(textField.text ?? "")
    }
}
