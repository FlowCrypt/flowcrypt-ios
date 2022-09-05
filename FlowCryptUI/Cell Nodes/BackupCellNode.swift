//
//  BackupCellNode.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 23/09/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class BackupCellNode: CellNode {
    private let textNode = ASTextNode2()
    private let insets: UIEdgeInsets

    public init(title: NSAttributedString, insets: UIEdgeInsets) {
        self.textNode.attributedText = title
        self.insets = insets
    }

    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASCenterLayoutSpec(
            centeringOptions: .XY,
            sizingOptions: .minimumXY,
            child: ASInsetLayoutSpec(
                insets: insets,
                child: textNode
            )
        )
    }
}
