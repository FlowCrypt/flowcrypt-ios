//
//  TextFieldCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class TextFieldCellNode: CellNode {
    struct Input {
        var placeholder: NSAttributedString? = nil
        var isSecureTextEntry = false
        var textInsets: CGFloat = -7
        var textAlignment: NSTextAlignment = .left
    }

    enum TextFieldActionType {
        case didEndEditing(String)
        case didBeginEditing(String)
        case editingChanged(String)
    }

    typealias TextFieldAction = (TextFieldActionType) -> Void

    private let textField = TextFieldNode()
    private var textFiledAction: TextFieldAction?

    var shouldEndEditing: ((UITextField) -> (Bool))?
    var shouldReturn: ((UITextField) -> (Bool))?

    init(_ input: Input, action: TextFieldAction? = nil) {
        super.init()
        textFiledAction = action

        textField.attributedPlaceholderText = input.placeholder
        textField.isSecureTextEntry = input.isSecureTextEntry
        textField.textAlignment = input.textAlignment
        textField.textInsets = input.textInsets

        textField.addTarget(
            self,
            action: #selector(onEditingChanged),
            for: UIControl.Event.editingChanged
        )


        textField.delegate = self
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

    @objc private func onEditingChanged() {
        textFiledAction?(.editingChanged(textField.text))
    }
}
