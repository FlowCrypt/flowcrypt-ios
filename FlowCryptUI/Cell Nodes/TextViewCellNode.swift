//
//  TextViewCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 05.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon

final public class TextViewCellNode: CellNode {
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

    public let textView = ASEditableTextNode()
    private let action: TextViewAction?
    private let height: CGFloat

    public init(_ input: Input, action: TextViewAction? = nil) {
        self.action = action
        self.height = input.preferredHeight
        super.init()
        textView.delegate = self
        textView.attributedPlaceholderText = input.placeholder
        textView.typingAttributes = [
            NSAttributedString.Key.font.rawValue: NSAttributedString.Style.regular(17).font,
            NSAttributedString.Key.foregroundColor.rawValue: input.textColor
        ]
    }

    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        textView.style.preferredSize.height = self.height
        return ASInsetLayoutSpec(insets: UIEdgeInsets(top: 8, left: 8, bottom: 0, right: 8), child: textView)
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
}
