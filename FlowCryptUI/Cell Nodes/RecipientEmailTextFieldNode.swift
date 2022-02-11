//
//  RecipientEmailTextFieldNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 10/02/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class RecipientEmailTextFieldNode: TextFieldCellNode {
    private var buttonAction: (() -> Void)?

    private lazy var buttonNode: ASButtonNode = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 16, weight: .light)
        let image = UIImage(systemName: "chevron.down", withConfiguration: configuration)
        let button = ASButtonNode()
        button.setImage(image, for: .normal)
        button.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.secondaryLabel)
        button.addTarget(self, action: #selector(onButtonTap), forControlEvents: .touchUpInside)
        return button
    }()

    public init(input: TextFieldCellNode.Input, action: TextFieldAction? = nil, buttonAction: (() -> Void)?) {
        super.init(input: input, action: action)

        self.buttonAction = buttonAction
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        if buttonAction != nil {
            textField.style.preferredSize = CGSize(
                // TODO
                width: constrainedSize.max.width - 32 - 32,
                height: input.height
            )

            let stack = ASStackLayoutSpec.horizontal()
            stack.children = [textField, buttonNode]

            return ASInsetLayoutSpec(insets: input.insets, child: stack)
        } else {
            textField.style.preferredSize = CGSize(
                width: input.width ?? (constrainedSize.max.width - input.insets.width),
                height: input.height
            )

            return ASInsetLayoutSpec(insets: input.insets, child: textField)
        }
    }

    @objc private func onButtonTap() {
        buttonAction?()
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
        return true
    }
}
