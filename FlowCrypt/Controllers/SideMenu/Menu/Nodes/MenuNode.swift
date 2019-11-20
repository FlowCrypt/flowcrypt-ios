//
//  MenuNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class MenuNode: CellNode {
    private let textNode = ASTextNode()
    private let imageNode = ASImageNode()

    init(input: FolderViewModel?) {
        super.init()
        automaticallyManagesSubnodes = true

        textNode.attributedText = input?.attributedTitle()
        imageNode.image = input?.image
    }

    override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        imageNode.style.preferredSize = imageNode.image != nil
            ? CGSize(width: 24, height: 24)
            : .zero
        let stack = ASStackLayoutSpec.horizontal().then {
            $0.spacing = imageNode.image != nil
                ? 6.0
                : 0.0 
            $0.children = [imageNode, textNode]
        }

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            child: stack
        )
    }
}
