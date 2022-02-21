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

    func createLayout(contentNode: ASDisplayNode, contentSize: CGSize, insets: UIEdgeInsets, buttonSize: CGSize) -> ASInsetLayoutSpec {
        if toggleButtonAction != nil {
            toggleButtonNode.style.preferredSize = buttonSize

            DispatchQueue.main.async {
                self.updateToggleButton(animated: false)
            }

            let contentWidth = contentSize.width - buttonSize.width - insets.width / 2 - 4
            contentNode.style.preferredSize = CGSize(
                width: max(0, contentWidth),
                height: contentSize.height
            )

            let stack = ASStackLayoutSpec.horizontal()
            stack.children = [contentNode, toggleButtonNode]
            return ASInsetLayoutSpec(insets: insets, child: stack)
        } else {
            contentNode.style.preferredSize = contentSize
            return ASInsetLayoutSpec(insets: insets, child: contentNode)
        }
    }
}
