//
//  CheckBoxTextNode.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 01/10/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public final class CheckBoxTextNode: CellNode {
    public struct Input {
        let title: NSAttributedString
        let insets: UIEdgeInsets
        let preferredSize: CGSize
        let checkBoxInput: CheckBoxNode.Input

        public init(
            title: NSAttributedString,
            insets: UIEdgeInsets,
            preferredSize: CGSize,
            checkBoxInput: CheckBoxNode.Input
        ) {
            self.title = title
            self.insets = insets
            self.preferredSize = preferredSize
            self.checkBoxInput = checkBoxInput
        }
    }

    private let textNode = ASTextNode2()
    private let input: Input
    private let checkBox: CheckBoxNode

    public init(input: Input) {
        self.textNode.attributedText = input.title
        self.input = input
        self.checkBox = CheckBoxNode(input.checkBoxInput)
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        checkBox.style.preferredSize = input.preferredSize

        let stack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: [checkBox, textNode]
        )


        return  ASInsetLayoutSpec(
            insets: input.insets,
            child: stack
        )

    }
}
