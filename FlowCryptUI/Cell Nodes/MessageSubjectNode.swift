//
//  MessageSubjectNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 05/11/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    

import AsyncDisplayKit

public final class MessageSubjectNode: CellNode {
    private let subjectNode = ASEditableTextNode()

    public init(_ subject: NSAttributedString?) {
        super.init()
        subjectNode.attributedText = subject
        subjectNode.maximumLinesToDisplay = 5
        DispatchQueue.main.async {
            self.subjectNode.textView.isSelectable = true
            self.subjectNode.textView.isEditable = false
        }
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        subjectNode.style.flexGrow = 1.0
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 16, left: 16, bottom: 4, right: 16),
            child: subjectNode
        )
    }
}
