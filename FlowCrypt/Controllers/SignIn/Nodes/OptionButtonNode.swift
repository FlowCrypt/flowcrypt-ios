//
//  OptionButtonNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class OptionButtonNode: ASCellNode {
    typealias Action = (SignInOption) -> ()

    private let buttons: [ASButtonNode]
    private var tapAction: Action?

    init(inputs: [SignInOption], action: Action?) {
        tapAction = action
        buttons = inputs.map {
            let button = ASButtonNode()
            button.setAttributedTitle($0.attributedTitle, for: .normal)
            button.accessibilityLabel = $0.rawValue
            return button
        }
        super.init()
        automaticallyManagesSubnodes = true
        buttons.forEach { $0.addTarget(self, action: #selector(onTap(_:)), forControlEvents: .touchUpInside) }
    }

    @objc private func onTap(_ sender: ASButtonNode) {
        guard let identifier = sender.accessibilityLabel, let button = SignInOption(rawValue: identifier) else { return }
        tapAction?(button)
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            child: ASCenterLayoutSpec(
                centeringOptions: .XY,
                sizingOptions: .minimumXY,
                child: ASStackLayoutSpec(
                    direction: .horizontal,
                    spacing: 16,
                    justifyContent: .center,
                    alignItems: .center,
                    children: buttons
                )
            )
        )
    }
}
