//
//  HeaderNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class HeaderNode: CellNode {
    private let titleNode = ASTextNode()
    private let subTitleNode = ASTextNode()

    init(input: MenuHeaderViewModel?) {
        super.init()
        automaticallyManagesSubnodes = true

        titleNode.attributedText = input?.title
        subTitleNode.attributedText = input?.subtitle
        backgroundColor = .main
    }

    override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 32, left: 16, bottom: 32, right: 16),
            child: ASStackLayoutSpec.vertical().then {
                $0.spacing = 8
                $0.children = [titleNode, subTitleNode]
            }
        )
    }
}
