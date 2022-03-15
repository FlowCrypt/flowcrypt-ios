//
//  RecipientToggleButtonNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 16/02/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

@objc protocol RecipientToggleButtonNode: AnyObject {
    var isToggleButtonRotated: Bool { get }
    var toggleButtonNode: ASButtonNode { get }
    var toggleButtonAction: (() -> Void)? { get }
    func onToggleButtonTap()
}

extension RecipientToggleButtonNode {
    func createToggleButton() -> ASButtonNode {
        let configuration = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
        let image = UIImage(systemName: "chevron.down", withConfiguration: configuration)
        let button = ASButtonNode()
        button.accessibilityIdentifier = "aid-recipients-toggle-button"
        button.setImage(image, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        button.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.secondaryLabel)
        button.addTarget(self, action: #selector(RecipientToggleButtonNode.onToggleButtonTap), forControlEvents: .touchUpInside)
        return button
    }

    func createNodeLabel(type: String, isEmpty: Bool) -> ASTextNode2 {
        let textNode = ASTextNode2()
        let textTitle = isEmpty ? "" : "compose_recipient_\(type)".localized
        textNode.attributedText = textTitle.attributed(.regular(17), color: .gray, alignment: .left)
        textNode.isAccessibilityElement = true
        textNode.style.preferredSize.width = 35
        return textNode
    }

    func updateToggleButton(animated: Bool) {
        func rotateButton(angle: CGFloat) {
            toggleButtonNode.view.transform = CGAffineTransform(rotationAngle: angle)
        }

        let angle = self.isToggleButtonRotated ? .pi : 0
        if animated {
            UIView.animate(withDuration: 0.3) {
                rotateButton(angle: angle)
            }
        } else {
            rotateButton(angle: angle)
        }
    }

    func createLayout(
        contentNode: ASDisplayNode,
        textNodeStack: ASInsetLayoutSpec,
        contentSize: CGSize,
        insets: UIEdgeInsets,
        buttonSize: CGSize
    ) -> ASInsetLayoutSpec {

        contentNode.style.flexGrow = 1
        contentNode.style.preferredSize.height = contentSize.height

        let stack = ASStackLayoutSpec.horizontal()
        stack.children = [textNodeStack, contentNode]

        if toggleButtonAction != nil {
            toggleButtonNode.style.preferredSize = buttonSize

            DispatchQueue.main.async {
                self.updateToggleButton(animated: false)
            }

            stack.children?.append(toggleButtonNode)
        }

        return ASInsetLayoutSpec(insets: insets, child: stack)
    }
}
