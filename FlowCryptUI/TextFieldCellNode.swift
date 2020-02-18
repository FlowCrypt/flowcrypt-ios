//
//  TextFieldCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final public class TextFieldCellNode: CellNode {
    public struct Input {
        public var placeholder: NSAttributedString? = nil
        public var isSecureTextEntry = false
        public var textInsets: CGFloat = -7
        public var textAlignment: NSTextAlignment = .left
        public var isLowercased = false
        public var insets: UIEdgeInsets = .zero
        public var height: CGFloat = 40

        public init(
            placeholder: NSAttributedString,
            isSecureTextEntry: Bool,
            textInsets: CGFloat,
            textAlignment: NSTextAlignment,
            isLowercased: Bool = false,
            insets: UIEdgeInsets = .zero,
            height: CGFloat = 40
        ) {
            self.placeholder = placeholder
            self.isSecureTextEntry = isSecureTextEntry
            self.textInsets = textInsets
            self.textAlignment = textAlignment
            self.isLowercased = isLowercased
            self.insets = insets
            self.height = height
        }
    }

    public enum TextFieldActionType {
        case didEndEditing(String?)
        case didBeginEditing(String?)
    }

    public typealias TextFieldAction = (TextFieldActionType) -> Void

    public let textField: TextFieldNode
    private var textFiledAction: TextFieldAction?
    private var shouldReturn: ((UITextField) -> (Bool))?

    public var shouldEndEditing: ((UITextField) -> (Bool))?
    public var attributedText: NSAttributedString? {
        didSet {
            textField.attributedText = attributedText
        }
    }
    public var isLowercased = false {
        didSet {
            self.textField.isLowercased = isLowercased
        }
    }

    private let input: Input

    public init(input: Input, action: TextFieldAction? = nil) {
        textField = TextFieldNode(prefferedHeight: input.height)
        self.input = input
        super.init()
        textFiledAction = action

        textField.attributedPlaceholderText = input.placeholder
        textField.isSecureTextEntry = input.isSecureTextEntry
        textField.textAlignment = input.textAlignment
        textField.textInsets = input.textInsets

        textField.delegate = self
    }

    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(insets: input.insets, child: textField)
    }

    public func onReturn(_ action: ((UITextField) -> (Bool))?) -> Self {
        shouldReturn = action
        return self
    }
    
    @discardableResult
    override public func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
        return true
    }
}

extension TextFieldCellNode: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        textFiledAction?(.didBeginEditing(textField.text))
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        textFiledAction?(.didEndEditing(textField.text))
    }

    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return shouldEndEditing?(textField) ?? true
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return shouldReturn?(textField) ?? true
    }
}
