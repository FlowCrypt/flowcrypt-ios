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
        var isLowercased = false
        var insets: UIEdgeInsets = .zero
    }

    enum TextFieldActionType {
        case didEndEditing(String)
        case didBeginEditing(String)
    }

    typealias TextFieldAction = (TextFieldActionType) -> Void

    private let textField = TextFieldNode()
    private var textFiledAction: TextFieldAction?

    var shouldEndEditing: ((UITextField) -> (Bool))?
    var shouldReturn: ((UITextField) -> (Bool))?
    var attributedText: NSAttributedString? {
        didSet {
            textField.attributedText = attributedText
        }
    }
    var isLowercased = false {
        didSet {
            self.textField.isLowercased = isLowercased
        }
    }

    private let input: Input
    init(_ input: Input, action: TextFieldAction? = nil) {
        self.input = input
        super.init()
        textFiledAction = action

        textField.attributedPlaceholderText = input.placeholder
        textField.isSecureTextEntry = input.isSecureTextEntry
        textField.textAlignment = input.textAlignment
        textField.textInsets = input.textInsets

        textField.delegate = self
    }

    func firstResponder() {
        textField.firstResponder()
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(insets: input.insets, child: textField)
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
