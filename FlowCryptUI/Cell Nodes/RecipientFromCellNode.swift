//
//  RecipientFromCellNode.swift
//  FlowCryptUI
//
//  Created by Ioan Moldovan on 6/16/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class RecipientFromCellNode: CellNode {
    private enum Constants {
        static let sectionInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        static let minimumLineSpacing: CGFloat = 4
    }

    private lazy var labelTextNode: ASTextNode2 = {
        let textNode = ASTextNode2()
        let textTitle = "compose_recipient_from".localized
        textNode.attributedText = textTitle.attributed(.regular(17), color: .lightGray, alignment: .left)
        textNode.style.preferredSize = CGSize(width: 45, height: 20)
        return textNode
    }()

    private lazy var valueTextNode: ASTextNode2 = {
        let textNode = ASTextNode2()
        textNode.accessibilityIdentifier = "aid-from-value-node"
        return textNode
    }()

    private let fromEmail: String

    private lazy var toggleButtonNode: ASButtonNode = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
        let image = UIImage(systemName: "chevron.down", withConfiguration: configuration)
        let button = ASButtonNode()
        button.accessibilityIdentifier = "aid-from-toggle-button"
        button.setImage(image, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 0, bottom: 0, right: 0)
        button.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.secondaryLabel)
        button.addTarget(self, action: #selector(onToggleButtonTap), forControlEvents: .touchUpInside)
        return button
    }()

    private var toggleButtonAction: (() -> Void)?

    public init(fromEmail: String, toggleButtonAction: (() -> Void)?) {
        self.fromEmail = fromEmail
        self.toggleButtonAction = toggleButtonAction
        super.init()
    }

    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let insets = UIEdgeInsets.deviceSpecificTextInsets(top: 0, bottom: 0)

        toggleButtonNode.style.preferredSize = CGSize(width: 40, height: 28)

        let stack = ASStackLayoutSpec.horizontal()
        stack.verticalAlignment = .center
        valueTextNode.style.flexGrow = 1
        valueTextNode.attributedText = fromEmail.attributed(.regular(17))

        let textNodeStack = ASInsetLayoutSpec(insets: .zero, child: labelTextNode)
        stack.children = [textNodeStack, valueTextNode, toggleButtonNode]

        return ASInsetLayoutSpec(insets: insets, child: stack)
    }

    @objc private func onToggleButtonTap() {
        toggleButtonAction?()
    }
}
