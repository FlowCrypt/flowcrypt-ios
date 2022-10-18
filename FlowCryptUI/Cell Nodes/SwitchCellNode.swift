//
//  SwitchCellNode.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 30/03/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

/// Node for representing text and switch toggle
public final class SwitchCellNode: CellNode {
    public struct Input {
        let attributedText: NSAttributedString
        let insets: UIEdgeInsets
        let backgroundColor: UIColor?
        let isOn: Bool

        public init(
            isOn: Bool,
            attributedText: NSAttributedString,
            insets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            backgroundColor: UIColor? = nil
        ) {
            self.attributedText = attributedText
            self.insets = insets
            self.backgroundColor = backgroundColor
            self.isOn = isOn
        }
    }

    private let textNode = ASTextNode()
    private lazy var switchNode = ASDisplayNode { () -> UIView in
        let view = UISwitch()
        view.isOn = self.input?.isOn ?? false
        view.addTarget(self, action: #selector(self.handleAction(_:)), for: .valueChanged)
        return view
    }

    private let input: Input?

    public typealias Action = (Bool) -> Void

    private let onAction: Action

    public init(input: Input?, action: @escaping Action) {
        self.input = input
        self.onAction = action

        super.init()
        self.textNode.attributedText = input?.attributedText
        self.automaticallyManagesSubnodes = true

        if let backgroundColor = input?.backgroundColor {
            self.backgroundColor = backgroundColor
        }
    }

    @objc private func handleAction(_ sender: UISwitch) {
        onAction(sender.isOn)
    }

    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        switchNode.style.preferredSize = CGSize(width: 100, height: 30)
        return ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: [
                ASInsetLayoutSpec(
                    insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 24),
                    child: textNode
                ),
                switchNode
            ]
        )
    }
}
