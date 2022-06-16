//
//  RecipientFromCellNode.swift
//  FlowCryptUI
//
//  Created by Ioan Moldovan on 6/16/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon

final public class RecipientFromCellNode: CellNode {
    private enum Constants {
        static let sectionInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        static let minimumLineSpacing: CGFloat = 4
    }

    lazy var labelTextNode: ASTextNode2 = {
        let textNode = ASTextNode2()
        let textTitle = "compose_recipient_from".localized
        textNode.attributedText = textTitle.attributed(.regular(17), color: .lightGray, alignment: .left)
        textNode.style.preferredSize = CGSize(width: 42, height: 32)
        return textNode
    }()

    lazy var valueTextNode: ASTextNode2 = {
        let textNode = ASTextNode2()
        return textNode
    }()

    public var fromEmail: String? {
        didSet {
            self.valueTextNode.attributedText = fromEmail?.attributed(.regular(17))
        }
    }

    lazy var toggleButtonNode: ASButtonNode = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
        let image = UIImage(systemName: "chevron.down", withConfiguration: configuration)
        let button = ASButtonNode()
        button.accessibilityIdentifier = "aid-recipients-toggle-button"
        button.setImage(image, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 0, bottom: 0, right: 0)
        button.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.secondaryLabel)
        button.addTarget(self, action: #selector(self.onToggleButtonTap), forControlEvents: .touchUpInside)
        return button
    }()

    var toggleButtonAction: (() -> Void)?

    public init(toggleButtonAction: (() -> Void)?) {
        super.init()
        self.toggleButtonAction = toggleButtonAction
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let insets = UIEdgeInsets.deviceSpecificTextInsets(top: 0, bottom: 0)

        toggleButtonNode.style.preferredSize = CGSize(width: 40, height: 32)

        let stack = ASStackLayoutSpec.horizontal()
        stack.verticalAlignment = .center
        valueTextNode.style.flexGrow = 1

        let textNodeStack = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0), child: labelTextNode)
        stack.children = [textNodeStack, valueTextNode, toggleButtonNode]

        return ASInsetLayoutSpec(insets: insets, child: stack)
    }

    @objc func onToggleButtonTap() {
        toggleButtonAction?()
    }
}
