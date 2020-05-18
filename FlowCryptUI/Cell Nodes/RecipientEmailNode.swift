//
//  RecipientEmailNode.swift
//  FlowCryptUIApplication
//
//  Created by Anton Kharchevskyi on 21/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import UIKit

final class RecipientEmailNode: CellNode {
    struct Input {
        let recipient: RecipientEmailsCellNode.Input
        let width: CGFloat
    }

    let titleNode = ASTextNode2()
    let input: Input
    let displayNode = ASDisplayNode()

    init(input: Input) {
        self.input = input
        super.init()
        titleNode.attributedText = "  ".attributed() + input.recipient.email + "  ".attributed()
        titleNode.backgroundColor = input.recipient.isSelected
            ? .titleNodeBackgroundColor
            : .titleNodeBackgroundColorSelected

        titleNode.cornerRadius = 8
        titleNode.clipsToBounds = true
        titleNode.borderWidth = 1
        titleNode.borderColor = input.recipient.isSelected
            ? UIColor.borderColor.cgColor
            : UIColor.borderColorSelected.cgColor

        displayNode.backgroundColor = .clear
    }

    override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
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

private extension UIColor {
    static var titleNodeBackgroundColorSelected: UIColor {
        UIColor.colorFor(
            darkStyle: UIColor.darkGray.withAlphaComponent(0.5),
            lightStyle: UIColor.white.withAlphaComponent(0.9)
        )
    }

    static var titleNodeBackgroundColor: UIColor {
        UIColor.colorFor(
            darkStyle: UIColor.lightGray,
            lightStyle: UIColor.black.withAlphaComponent(0.1)
        )
    }

    static var borderColorSelected: UIColor {
        UIColor.colorFor(
            darkStyle: UIColor.white.withAlphaComponent(0.5),
            lightStyle: UIColor.black.withAlphaComponent(0.3)
        )
    }

    static var borderColor: UIColor {
        UIColor.colorFor(
            darkStyle: UIColor.white.withAlphaComponent(0.5),
            lightStyle: black.withAlphaComponent(0.4)
        )
    }
}
