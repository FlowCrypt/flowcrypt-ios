//
//  TextFieldCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public final class TextFieldCellNode: CellNode {
    public struct Input {
        public var placeholder: NSAttributedString?
        public var isSecureTextEntry = false
        public var textInsets: CGFloat = -7
        public var textAlignment: NSTextAlignment = .left
        public var isLowercased = false
        public var insets: UIEdgeInsets = .zero
        public var height: CGFloat = 40
        public var width: CGFloat?

        public init(
            placeholder: NSAttributedString = NSAttributedString(string: "PLACEHOLDER"),
            isSecureTextEntry: Bool = false,
            textInsets: CGFloat = .zero,
            textAlignment: NSTextAlignment = .left,
            isLowercased: Bool = false,
            insets: UIEdgeInsets = .zero,
            height: CGFloat = 40,
            width: CGFloat? = nil
        ) {
            self.placeholder = placeholder
            self.isSecureTextEntry = isSecureTextEntry
            self.textInsets = textInsets
            self.textAlignment = textAlignment
            self.isLowercased = isLowercased
            self.insets = insets
            self.height = height
            self.width = width
        }
    }

    private var textFiledAction: TextFieldAction?

    private let input: Input

    public let textField: TextFieldNode

    public var attributedText: NSAttributedString? {
        didSet {
            textField.attributedText = attributedText
        }
    }

    public var isLowercased = false {
        didSet {
            textField.isLowercased = isLowercased
        }
    }

    public init(input: Input, action: TextFieldAction? = nil) {
        textField = TextFieldNode(preferredHeight: input.height, action: action)
        self.input = input
        super.init()
        textFiledAction = action

        textField.attributedPlaceholderText = input.placeholder
        textField.isSecureTextEntry = input.isSecureTextEntry
        textField.textAlignment = input.textAlignment
        textField.textInsets = input.textInsets
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        textField.style.preferredSize = CGSize(
            width: input.width ?? constrainedSize.max.width,
            height: input.height
        )
        return ASInsetLayoutSpec(insets: input.insets, child: textField)
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
        return true
    }
}

public extension TextFieldCellNode {
    func onShouldReturn(_ action: TextFieldNode.ShouldReturnAction?) -> Self {
        textField.shouldReturn = action
        return self
    }

    func onShouldChangeCharacters(_ action: TextFieldNode.ShouldChangeAction?) -> Self {
        textField.shouldChangeCharacters = action
        return self
    }
}
