//
//  TextFieldCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
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
        public var backgroundColor: UIColor?
        public var keyboardType: UIKeyboardType
        public let accessibilityIdentifier: String?

        public init(
            placeholder: NSAttributedString = NSAttributedString(string: "PLACEHOLDER"), // TODO: - Anton
            isSecureTextEntry: Bool = false,
            textInsets: CGFloat = .zero,
            textAlignment: NSTextAlignment = .left,
            isLowercased: Bool = false,
            insets: UIEdgeInsets = .zero,
            height: CGFloat = 40,
            width: CGFloat? = nil,
            backgroundColor: UIColor? = nil,
            keyboardType: UIKeyboardType = .default,
            accessibilityIdentifier: String? = nil
        ) {
            self.placeholder = placeholder
            self.isSecureTextEntry = isSecureTextEntry
            self.textInsets = textInsets
            self.textAlignment = textAlignment
            self.isLowercased = isLowercased
            self.insets = insets
            self.height = height
            self.width = width
            self.backgroundColor = backgroundColor
            self.keyboardType = keyboardType
            self.accessibilityIdentifier = accessibilityIdentifier
        }
    }

    private var textFieldAction: TextFieldAction?

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
        textField = TextFieldNode(
            preferredHeight: input.height,
            action: action,
            accessibilityIdentifier: input.accessibilityIdentifier
        )
        self.input = input
        super.init()
        textFieldAction = action

        textField.attributedPlaceholderText = input.placeholder
        textField.isSecureTextEntry = input.isSecureTextEntry
        textField.textAlignment = input.textAlignment
        textField.textInsets = input.textInsets
        textField.keyboardType = input.keyboardType
        textField.accessibilityIdentifier = input.accessibilityIdentifier
        if let color = input.backgroundColor {
            backgroundColor = color
        }
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        textField.style.preferredSize = CGSize(
            width: input.width ?? (constrainedSize.max.width - input.insets.width),
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
