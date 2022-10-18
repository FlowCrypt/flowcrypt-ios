//
//  CheckBoxTextNode.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 01/10/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class CheckBoxTextNode: CellNode {
    public struct Input {
        let title: NSAttributedString
        let subtitle: NSAttributedString?
        let insets: UIEdgeInsets
        let preferredSize: CGSize
        let checkBoxInput: CheckBoxNode.Input

        public init(
            title: NSAttributedString,
            subtitle: NSAttributedString? = nil,
            insets: UIEdgeInsets,
            preferredSize: CGSize,
            checkBoxInput: CheckBoxNode.Input
        ) {
            self.title = title
            self.insets = insets
            self.subtitle = subtitle
            self.preferredSize = preferredSize
            self.checkBoxInput = checkBoxInput
        }
    }

    private let textNode = ASTextNode2()
    private let subtitleTextNode = ASTextNode2()
    private let input: Input
    private let checkBox: CheckBoxNode

    public init(input: Input) {
        self.textNode.attributedText = input.title
        self.input = input
        self.checkBox = CheckBoxNode(input.checkBoxInput)

        self.textNode.maximumNumberOfLines = 0
        self.textNode.truncationMode = .byTruncatingTail

        if let subtitle = input.subtitle {
            subtitleTextNode.attributedText = subtitle
            subtitleTextNode.maximumNumberOfLines = 0
            subtitleTextNode.truncationMode = .byTruncatingTail
        }
    }

    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        checkBox.style.preferredSize = input.preferredSize

        if input.subtitle != nil {
            let textStack = ASStackLayoutSpec()
            textStack.direction = .vertical
            textStack.style.flexGrow = 1
            textStack.style.flexShrink = 1
            textStack.children = [textNode, subtitleTextNode]

            let stack = ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 8,
                justifyContent: .start,
                alignItems: .center,
                children: [checkBox, textStack]
            )

            return ASInsetLayoutSpec(
                insets: input.insets,
                child: stack
            )
        } else {
            let stack = ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 8,
                justifyContent: .start,
                alignItems: .center,
                children: [checkBox, textNode]
            )

            return ASInsetLayoutSpec(
                insets: input.insets,
                child: stack
            )
        }
    }
}
