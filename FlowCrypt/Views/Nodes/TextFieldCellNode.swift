//
//  TextFieldCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

// TODO: Anton - change in setup as well
final class TextFieldCellNode: CellNode {
    enum TextFieldActionType {
        case didEndEditing(String)
        case didBeginEditing(String)
    }

    typealias TextFieldAction = (TextFieldActionType) -> Void

    private let textField = TextFieldNode()
    private var textFiledAction: TextFieldAction?

    var shouldEndEditing: ((UITextField) -> (Bool))?
    var shouldReturn: ((UITextField) -> (Bool))?

    // TODO: Anton -
    init(_ placeholder: NSAttributedString? = nil, textFiledAction: TextFieldAction? = nil) {
        super.init()
        self.textFiledAction = textFiledAction
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

extension TextFieldCellNode: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let text = textField.text ?? ""
        textFiledAction?(.didBeginEditing(text))
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let text = textField.text ?? ""
        textFiledAction?(.didEndEditing(text))
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return shouldEndEditing?(textField) ?? true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return shouldReturn?(textField) ?? true
    }
}
