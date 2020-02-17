//
//  TextSubjectNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class TextSubjectNode: CellNode {
    private let textNode = ASEditableTextNode()

    init(_ text: NSAttributedString?) {
        super.init()
        textNode.attributedText = text
        DispatchQueue.main.async {
            self.textNode.textView.isSelectable = true
            self.textNode.textView.isEditable = false
        }
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        textNode.style.flexGrow = 1.0
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
            child: textNode
        )
    }
}
