//
//  BackupCellNode.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 23/09/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public final class BackupCellNode: CellNode {
    private let textNode = ASTextNode2()
    private let insets: UIEdgeInsets

    public init(title: NSAttributedString, insets: UIEdgeInsets) {
        self.textNode.attributedText = title
        self.insets = insets
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let circle = CheckBoxNode(CheckBoxNode.Input(color: .red, disabledColor: .blue, strokeWidth: 2))
        circle.style.preferredSize.height = 40
        circle.style.preferredSize.width = 40
        return ASCenterLayoutSpec(
            centeringOptions: .XY,
            sizingOptions: .minimumXY,
            child: ASInsetLayoutSpec(
                insets: insets,
                child: circle
            )
        )
    }
}
