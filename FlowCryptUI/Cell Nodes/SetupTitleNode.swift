//
//  SetupTitleNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class SetupTitleNode: CellNode {
    public struct Input {
        let title: NSAttributedString
        let insets: UIEdgeInsets
        let selectedLineColor: UIColor?
        let backgroundColor: UIColor
        let accessibilityIdentifier: String?

        public init(
            title: NSAttributedString,
            insets: UIEdgeInsets,
            selectedLineColor: UIColor? = nil,
            backgroundColor: UIColor,
            accessibilityIdentifier: String? = nil
        ) {
            self.title = title
            self.insets = insets
            self.selectedLineColor = selectedLineColor
            self.backgroundColor = backgroundColor
            self.accessibilityIdentifier = accessibilityIdentifier
        }
    }
    private let input: Input
    private let textNode = ASTextNode2()
    private let selectedNode = ASDisplayNode()

    public init(_ input: Input) {
        self.input = input
        super.init()
        textNode.attributedText = input.title
        textNode.isAccessibilityElement = true
        textNode.accessibilityIdentifier = input.accessibilityIdentifier
        backgroundColor = input.backgroundColor
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let layout = ASInsetLayoutSpec(
            insets: input.insets,
            child: ASCenterLayoutSpec(
                centeringOptions: .XY,
                sizingOptions: .minimumXY,
                child: textNode
            )
        )
        if input.selectedLineColor != nil {
            selectedNode.style.flexGrow = 1.0
            selectedNode.style.preferredSize.height = 2
            return ASStackLayoutSpec.vertical().then {
                $0.spacing = 4
                $0.children = [
                    ASInsetLayoutSpec(insets: input.insets, child: textNode),
                    selectedNode
                ]
            }
        } else {
            return layout
        }
    }

    override public var isSelected: Bool {
        didSet {
            selectedNode.backgroundColor = isSelected
                ? input.selectedLineColor :
                .clear
        }
    }
}
