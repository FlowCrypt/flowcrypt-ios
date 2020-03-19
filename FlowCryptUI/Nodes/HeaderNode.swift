//
//  HeaderNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public final class HeaderNode: CellNode {
    public struct Input {
        public let title: NSAttributedString
        public let subtitle: NSAttributedString?

        public init(title: NSAttributedString, subtitle: NSAttributedString?) {
            self.title = title
            self.subtitle = subtitle
        }
    }

    private let titleNode = ASTextNode()
    private let subTitleNode = ASTextNode()

    public init(input: HeaderNode.Input?) {
        super.init()
        automaticallyManagesSubnodes = true

        titleNode.attributedText = input?.title
        subTitleNode.attributedText = input?.subtitle
        backgroundColor = .main
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 32, left: 16, bottom: 32, right: 16),
            child: ASStackLayoutSpec.vertical().then {
                $0.spacing = 8
                $0.children = [titleNode, subTitleNode]
            }
        )
    }
}
