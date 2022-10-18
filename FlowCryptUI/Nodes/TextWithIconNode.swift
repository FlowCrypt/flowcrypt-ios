//
//  TextWithIconNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 18/11/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class TextWithIconNode: CellNode {
    public struct Input {
        public let title: NSAttributedString
        public let image: UIImage?
        public let imageSize: CGSize
        public let nodeInsets: UIEdgeInsets

        public init(
            title: NSAttributedString,
            image: UIImage?,
            imageSize: CGSize = CGSize(width: 20, height: 20),
            nodeInsets: UIEdgeInsets = .deviceSpecificTextInsets(top: 8, bottom: 8)
        ) {
            self.title = title
            self.image = image
            self.imageSize = imageSize
            self.nodeInsets = nodeInsets
        }
    }

    private let titleNode = ASTextNode2()
    private let imageNode = ASImageNode()

    private let input: TextWithIconNode.Input

    public init(input: TextWithIconNode.Input) {
        self.input = input
        super.init()
        automaticallyManagesSubnodes = true

        titleNode.attributedText = input.title
        imageNode.image = input.image
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        imageNode.style.preferredSize = input.imageSize

        return ASInsetLayoutSpec(
            insets: input.nodeInsets,
            child: ASStackLayoutSpec.horizontal().then {
                $0.spacing = 8
                $0.children = [imageNode, titleNode]
            }
        )
    }
}
