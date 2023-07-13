//
//  MenuSeparatorCellNode.swift
//  FlowCryptUI
//
//  Created by Ioan Moldovan on 7/13/23
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

open class MenuSeparatorCellNode: ASCellNode {
    let separatorView: ASDisplayNode = {
        let node = ASDisplayNode()
        node.backgroundColor = .separator
        node.style.flexGrow = 1.0
        node.style.preferredSize.height = 0.5
        return node
    }()

    override public init() {
        super.init()
        addSubnode(separatorView)
    }

    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(insets: .deviceSpecificTextInsets(top: 0, bottom: 0), child: separatorView)
    }
}
