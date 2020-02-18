//
//  MenuNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public final class MenuNode: ASCellNode {
    public struct Input {
        let attributedText: NSAttributedString
        let image: UIImage?

        public init(
            attributedText: NSAttributedString,
            image: UIImage?
        ) {
            self.attributedText = attributedText
            self.image = image
        }
    }

    private let textNode = ASTextNode()
    private let imageNode = ASImageNode()

    public init(input: Input?) {
        super.init()
        textNode.attributedText = input?.attributedText
        imageNode.image = input?.image
        automaticallyManagesSubnodes = true
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        imageNode.style.preferredSize = imageNode.image != nil
            ? CGSize(width: 24, height: 24)
            : .zero

        let stack = ASStackLayoutSpec.horizontal()
        stack.spacing = imageNode.image != nil
                ? 6.0
                : 0.0
        stack.children = [imageNode, textNode]

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            child: stack
        )
    }
}
