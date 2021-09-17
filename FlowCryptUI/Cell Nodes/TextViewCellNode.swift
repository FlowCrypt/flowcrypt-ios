//
//  TextViewCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 05.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon

public final class TextViewCellNode: CellNode {
    public struct Input {
        var placeholder: NSAttributedString
        var preferredHeight: CGFloat
        let textColor: UIColor

        public init(
            placeholder: NSAttributedString,
            preferredHeight: CGFloat,
            textColor: UIColor
        ) {
            self.placeholder = placeholder
            self.preferredHeight = preferredHeight
            self.textColor = textColor
        }
    }

    public enum TextViewActionType {
        case didEndEditing(NSAttributedString?)
        case didBeginEditing(NSAttributedString?)
    }

    public typealias TextViewAction = (TextViewActionType) -> Void
    public typealias TextViewUpdatedSize = (TextViewCellNode, CGFloat) -> Void

    public let textView = ASEditableTextNode()
    private let action: TextViewAction?
    public var height: CGFloat
    private let textViewSizeUpdated: TextViewUpdatedSize?

    public init(
        _ input: Input,
        textViewSizeUpdated: TextViewUpdatedSize? = nil,
        action: TextViewAction? = nil
    ) {
        self.action = action
        height = input.preferredHeight
        self.textViewSizeUpdated = textViewSizeUpdated
        super.init()
        textView.delegate = self
        textView.attributedPlaceholderText = input.placeholder
        textView.typingAttributes = [
            NSAttributedString.Key.font.rawValue: NSAttributedString.Style.regular(17).font,
            NSAttributedString.Key.foregroundColor.rawValue: input.textColor,
        ]
    }
    
    public func setHeight(_ height: CGFloat) {
        self.height = height
        setNeedsLayout()
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        textView.style.preferredSize.height = height
        return ASInsetLayoutSpec(insets: UIEdgeInsets(top: 8, left: 8, bottom: 0, right: 8), child: textView)
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
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
        textViewSizeUpdated?(self, calculatedHeight)
    }
}
