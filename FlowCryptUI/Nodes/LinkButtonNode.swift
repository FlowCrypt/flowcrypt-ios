//
//  OptionButtonNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public protocol Link {
    var url: URL? { get }
    var attributedTitle: NSAttributedString { get }
    var title: String { get }
    var rawValue: String { get }
    var identifier: String? { get }
}

public final class LinkButtonNode: CellNode {
    public typealias Action = (String) -> Void

    private let buttons: [ASButtonNode]
    private var tapAction: Action?

    public init(_ inputs: [Link], action: Action?) {
        tapAction = action
        buttons = inputs.map {
            let button = ASButtonNode()
            button.setAttributedTitle($0.attributedTitle, for: .normal)
            button.accessibilityLabel = $0.identifier ?? $0.rawValue
            return button
        }
        super.init()
        automaticallyManagesSubnodes = true
        for button in buttons {
            button.addTarget(self, action: #selector(onTap(_:)), forControlEvents: .touchUpInside)
        }
        selectionStyle = .none
    }

    @objc private func onTap(_ sender: ASButtonNode) {
        guard let identifier = sender.accessibilityLabel else { return }
        tapAction?(identifier)
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 30, left: 16, bottom: 8, right: 18),
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
