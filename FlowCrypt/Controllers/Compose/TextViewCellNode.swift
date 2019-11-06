//
//  TextViewCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 05.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class TextViewCellNode: CellNode {
    struct Input {
        var placeholder: NSAttributedString
        var prefferedHeight: CGFloat
    }

    enum TextViewActionType {
        case didEndEditing(NSAttributedString?)
        case didBeginEditing(NSAttributedString?)
    }

    typealias TextViewAction = (TextViewActionType) -> Void

    let textView = ASEditableTextNode()
    private let action: TextViewAction?
    private let height: CGFloat

    init(_ input: Input, action: TextViewAction? = nil) {
        self.action = action
        self.height = input.prefferedHeight
        super.init()
        textView.delegate = self
        textView.attributedPlaceholderText = input.placeholder
        textView.typingAttributes = [
            NSAttributedString.Key.font.rawValue: NSAttributedString.Style.regular(17).font,
            NSAttributedString.Key.foregroundColor.rawValue: UIColor.black
        ]
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        textView.style.preferredSize.height = self.height
        return ASInsetLayoutSpec(insets: UIEdgeInsets(top: 8, left: 8, bottom: 0, right: 8), child: textView)
    }

    func firstResponder() {
        textView.becomeFirstResponder()
    }
}

extension TextViewCellNode: ASEditableTextNodeDelegate {
    func editableTextNodeDidBeginEditing(_ editableTextNode: ASEditableTextNode) {
        action?(.didBeginEditing(editableTextNode.attributedText))
    }
}
