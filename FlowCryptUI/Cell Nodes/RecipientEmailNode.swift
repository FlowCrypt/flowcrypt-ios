//
//  RecipientEmailNode.swift
//  FlowCryptUIApplication
//
//  Created by Anton Kharchevskyi on 21/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import FlowCryptCommon

final class RecipientEmailNode: CellNode {
    struct Input {
        let recipient: RecipientEmailsCellNode.Input
        let width: CGFloat
    }

    let titleNode = ASTextNode()
    let input: Input
    let displayNode = ASDisplayNode()

    init(input: Input) {
        self.input = input
        super.init()
        titleNode.attributedText = "  ".attributed() + input.recipient.email + "  ".attributed()
        titleNode.backgroundColor = input.recipient.state.backgroundColor

        titleNode.cornerRadius = 8
        titleNode.clipsToBounds = true
        titleNode.borderWidth = 1
        titleNode.borderColor = input.recipient.state.borderColor.cgColor

        displayNode.backgroundColor = .clear
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        displayNode.style.preferredSize.width = input.width
        displayNode.style.preferredSize.height = 1 
        let spec = ASStackLayoutSpec()
        spec.children = [displayNode, titleNode]
        spec.direction = .vertical
        spec.alignItems = .baselineFirst
        return ASInsetLayoutSpec(
            insets: .zero,
            child: spec
        )
    }
}
