//
//  KeySettingCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class KeySettingCellNode: CellNode {
    struct Input {
        let title, subtitle, date: NSAttributedString
    }
    private let titleNode = ASTextNode()
    private let dateNode = ASTextNode()
    private let subTitleNode = ASTextNode()
    private let separatorNode = ASDisplayNode()

    init(with input: KeySettingCellNode.Input) {
        titleNode.attributedText = input.title
        dateNode.attributedText = input.subtitle
        subTitleNode.attributedText = input.date

        titleNode.maximumNumberOfLines = 1
        dateNode.maximumNumberOfLines = 1
        subTitleNode.maximumNumberOfLines = 0

        titleNode.truncationMode = .byTruncatingTail
        subTitleNode.truncationMode = .byTruncatingTail

        separatorNode.backgroundColor = .lightGray
    }

    override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let nameLocationStack = ASStackLayoutSpec.vertical()
        nameLocationStack.spacing = 6
        nameLocationStack.style.flexShrink = 1.0
        nameLocationStack.style.flexGrow = 1.0
        separatorNode.style.flexGrow = 1.0
        separatorNode.style.preferredSize.height = 1.0

        nameLocationStack.children = [titleNode, subTitleNode]

        let headerStackSpec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .baselineFirst,
            children: [nameLocationStack, dateNode]
        )

        let finalSpec = ASStackLayoutSpec.vertical()
        finalSpec.children = [headerStackSpec, separatorNode]
        finalSpec.spacing = 8
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            child: finalSpec
        )
    }
}
