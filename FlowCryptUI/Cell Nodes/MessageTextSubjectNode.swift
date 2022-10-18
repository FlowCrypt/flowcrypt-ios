//
//  TextSubjectNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class MessageTextSubjectNode: CellNode {
    private let textNode = ASEditableTextNode()

    public init(_ text: NSAttributedString?, index: Int) {
        super.init()
        textNode.attributedText = text
        textNode.isAccessibilityElement = true
        textNode.accessibilityIdentifier = "aid-message-\(index)"
        textNode.accessibilityValue = text?.string

        DispatchQueue.main.async {
            self.textNode.textView.isSelectable = true
            self.textNode.textView.isEditable = false
        }
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        textNode.style.flexGrow = 1.0
        return ASInsetLayoutSpec(
            insets: .deviceSpecificTextInsets(top: 8, bottom: 8),
            child: textNode
        )
    }
}
