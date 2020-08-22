//
//  ContactCellNode.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 22/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public final class ContactCellNode: CellNode {
    public struct Input {
        let name: NSAttributedString?
        let email: NSAttributedString
        let insets: UIEdgeInsets

        public init(
            name: NSAttributedString?,
            email: NSAttributedString,
            insets: UIEdgeInsets
        ) {
            self.name = name
            self.email = email
            self.insets = insets
        }
    }

    private let nameNode = ASTextNode2()
    private let emailNode = ASTextNode2()
    private let input: Input

    public init(input: Input) {
        self.input = input
        super.init()
        nameNode.attributedText = input.name
        emailNode.attributedText = input.email
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        if input.name == nil {
            return ASInsetLayoutSpec(
                insets: input.insets,
                child: emailNode
            )
        } else {
            return ASInsetLayoutSpec(
                insets: input.insets,
                child: ASStackLayoutSpec(
                    direction: .vertical,
                    spacing: 8,
                    justifyContent: .start,
                    alignItems: .baselineFirst,
                    children: [nameNode, emailNode]
                )
            )
        }
    }
}
