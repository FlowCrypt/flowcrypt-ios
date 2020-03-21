//
//  SetupTitleNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public final class SetupTitleNode: CellNode {
    private let textNode = ASTextNode()
    private let insets: UIEdgeInsets
    private let selectedNode = ASDisplayNode()
    private var selectedLineColor: UIColor?
    
    public init(
        title: NSAttributedString,
        insets: UIEdgeInsets,
        selectedLineColor: UIColor? = nil
    ) {
        self.insets = insets
        self.selectedLineColor = selectedLineColor
        super.init()
        textNode.attributedText = title
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let layout = ASInsetLayoutSpec(
            insets: insets,
            child: ASCenterLayoutSpec(
                centeringOptions: .XY,
                sizingOptions: .minimumXY,
                child: textNode
            )
        )
        if selectedLineColor != nil {
            selectedNode.style.flexGrow = 1.0
            selectedNode.style.preferredSize.height = 2
            return ASStackLayoutSpec.vertical().then {
                $0.spacing = 4
                $0.children = [
                    ASInsetLayoutSpec(insets: insets, child: textNode),
                    selectedNode
                ]
            }
        } else {
            return layout
        }
    }
    
    public override var isSelected: Bool {
        didSet {
            selectedNode.backgroundColor = isSelected ? selectedLineColor : .clear
        }
    }
}
