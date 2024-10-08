//
//  TextViewCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 05.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon

public final class TextViewCellNode: CellNode {
    public struct Input {
        var placeholder: NSAttributedString
        var preferredHeight: CGFloat
        let textColor: UIColor
        let accessibilityIdentifier: String?

        public init(
            placeholder: NSAttributedString,
            preferredHeight: CGFloat,
            textColor: UIColor,
            accessibilityIdentifier: String? = nil
        ) {
            self.placeholder = placeholder
            self.preferredHeight = preferredHeight
            self.textColor = textColor
            self.accessibilityIdentifier = accessibilityIdentifier
        }
    }

    public enum TextViewActionType {
        case didEndEditing(NSAttributedString?)
        case didBeginEditing(NSAttributedString?)
        case editingChanged(NSAttributedString?)
        case heightChanged(UITextView)
    }

    public typealias TextViewAction = (TextViewActionType) -> Void

    public let textView = ASEditableTextNode()
    private let action: TextViewAction?
    public var height: CGFloat

    public init(
        _ input: Input,
        action: TextViewAction? = nil
    ) {
        self.action = action
        height = input.preferredHeight
        super.init()

        textView.delegate = self
        textView.attributedPlaceholderText = input.placeholder
        textView.typingAttributes = [
            NSAttributedString.Key.font.rawValue: NSAttributedString.Style.regular(17).font,
            NSAttributedString.Key.foregroundColor.rawValue: input.textColor
        ]

        DispatchQueue.main.async {
            self.textView.textView.accessibilityIdentifier = input.accessibilityIdentifier
        }
    }

    public func setText(text: String) {
        self.textView.textView.attributedText = text.attributed(.regular(17))
    }

    private func setHeight(_ height: CGFloat) {
        let shouldAnimate = self.height < height

        self.height = height
        setNeedsLayout()

        if shouldAnimate { action?(.heightChanged(textView.textView)) }
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        textView.style.preferredSize.height = height

        return ASInsetLayoutSpec(
            insets: .deviceSpecificTextInsets(top: 8, bottom: 0),
            child: textView
        )
    }

    @discardableResult
    override public func becomeFirstResponder() -> Bool {
        DispatchQueue.main.async {
            _ = self.textView.textView.becomeFirstResponder()
        }
        return true
    }
}

extension TextViewCellNode: ASEditableTextNodeDelegate {
    public func editableTextNodeDidBeginEditing(_ editableTextNode: ASEditableTextNode) {
        action?(.didBeginEditing(editableTextNode.attributedText))
    }

    public func editableTextNodeDidFinishEditing(_ editableTextNode: ASEditableTextNode) {
        action?(.didEndEditing(editableTextNode.attributedText))
    }

    public func editableTextNodeDidUpdateText(_ editableTextNode: ASEditableTextNode) {
        let calculatedHeight = editableTextNode.textView.sizeThatFits(textView.frame.size).height
        setHeight(calculatedHeight)
        action?(.editingChanged(editableTextNode.attributedText))
    }
}
