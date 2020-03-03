//
//  MenuNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

/// Node for representing text and optional image
public final class InfoCellNode: ASCellNode {
    public struct Input {
        let attributedText: NSAttributedString
        let image: UIImage?
        let insets: UIEdgeInsets

        public init(
            attributedText: NSAttributedString,
            image: UIImage?,
            insets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        ) {
            self.attributedText = attributedText
            self.image = image
            self.insets = insets
        }
    }

    private let textNode = ASTextNode()
    private let imageNode = ASImageNode()
    private let input: Input?

    public init(input: Input?) {
        self.input = input
        super.init()
        self.textNode.attributedText = input?.attributedText
        self.imageNode.image = input?.image
        self.automaticallyManagesSubnodes = true
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
            insets: input?.insets ?? .zero,
            child: stack
        )
    }
}
