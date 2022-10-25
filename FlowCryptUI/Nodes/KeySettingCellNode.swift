//
//  KeySettingCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class KeySettingCellNode: CellNode {
    public struct Input {
        let title, subtitle, date: NSAttributedString

        public init(
            title: NSAttributedString,
            subtitle: NSAttributedString,
            date: NSAttributedString
        ) {
            self.title = title
            self.subtitle = subtitle
            self.date = date
        }
    }

    private let titleNode = ASTextNode2()
    private let dateNode = ASTextNode2()
    private let subTitleNode = ASTextNode2()
    private let separatorNode = ASDisplayNode()

    public init(with input: KeySettingCellNode.Input) {
        titleNode.attributedText = input.title
        titleNode.accessibilityIdentifier = "aid-key-title"
        dateNode.attributedText = input.date
        dateNode.accessibilityIdentifier = "aid-key-date-created"
        subTitleNode.attributedText = input.subtitle
        subTitleNode.accessibilityIdentifier = "aid-key-subtitle"

        titleNode.maximumNumberOfLines = 0
        dateNode.maximumNumberOfLines = 1
        subTitleNode.maximumNumberOfLines = 0

        titleNode.truncationMode = .byTruncatingTail
        subTitleNode.truncationMode = .byTruncatingTail

        separatorNode.backgroundColor = .lightGray
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
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
            insets: .deviceSpecificTextInsets(top: 16, bottom: 16),
            child: finalSpec
        )
    }
}
