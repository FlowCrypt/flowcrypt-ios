//
//  RecipientEmailTextFieldNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 10/02/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class RecipientEmailTextFieldNode: TextFieldCellNode {
    private var toggleButtonAction: (() -> Void)?

    private lazy var toggleButtonNode: ASButtonNode = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
        let image = UIImage(systemName: "chevron.down", withConfiguration: configuration)
        let button = ASButtonNode()
        button.setImage(image, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        button.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.secondaryLabel)
        button.addTarget(self, action: #selector(onToggleButtonTap), forControlEvents: .touchUpInside)
        return button
    }()

    var isToggleButtonRotated = false {
        didSet {
            updateButton()
        }
    }

    public init(
        input: TextFieldCellNode.Input,
        action: TextFieldAction? = nil,
        isToggleButtonRotated: Bool,
        toggleButtonAction: (() -> Void)?
    ) {
        super.init(input: input, action: action)

        self.isToggleButtonRotated = isToggleButtonRotated
        self.toggleButtonAction = toggleButtonAction

        self.textField.accessibilityIdentifier = input.accessibilityIdentifier
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let textFieldWidth = input.width ?? (constrainedSize.max.width - input.insets.width)

        if toggleButtonAction != nil {
            let buttonSize = CGSize(width: 40, height: 40)

            toggleButtonNode.style.preferredSize = buttonSize
            textField.style.preferredSize = CGSize(
                width: textFieldWidth - buttonSize.width - input.insets.right - 4,
                height: input.height
            )

            let stack = ASStackLayoutSpec.horizontal()
            stack.children = [textField, toggleButtonNode]

            DispatchQueue.main.async {
                self.toggleButtonNode.view.transform = CGAffineTransform(rotationAngle: self.isToggleButtonRotated ? .pi : 0)
            }

            return ASInsetLayoutSpec(insets: input.insets, child: stack)
        } else {
            textField.style.preferredSize = CGSize(
                width: textFieldWidth,
                height: input.height
            )

            return ASInsetLayoutSpec(insets: input.insets, child: textField)
        }
    }

    private func updateButton() {
        UIView.animate(withDuration: 0.3) {
            self.toggleButtonNode.view.transform = CGAffineTransform(rotationAngle: self.isToggleButtonRotated ? .pi : 0)
        }
    }

    @objc private func onToggleButtonTap() {
        isToggleButtonRotated.toggle()
        toggleButtonAction?()
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
        return true
    }
}
