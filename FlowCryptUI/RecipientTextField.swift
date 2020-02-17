//
//  RecipientTextField.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 17/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import AsyncDisplayKit

final public class DividerNode: ASCellNode {
    private let line = ASDisplayNode()
    private let inset: UIEdgeInsets

    public init(
        inset: UIEdgeInsets = .zero,
        color: UIColor = .red,
        height: CGFloat = 10
    ) {
        self.inset = inset
        super.init()
        line.backgroundColor = color
    }

    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        backgroundColor = .red
        line.style.preferredSize.height = 100
        line.backgroundColor = .red
        return ASInsetLayoutSpec(insets: inset, child: line)
    }
}
