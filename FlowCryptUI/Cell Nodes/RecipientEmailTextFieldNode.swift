//
//  RecipientEmailTextFieldNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 10/02/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class RecipientEmailTextFieldNode: TextFieldCellNode {

    override public init(
        input: TextFieldCellNode.Input,
        action: TextFieldAction? = nil
    ) {
        super.init(input: input, action: action)

        self.isLowercased = true
    }

    @discardableResult
    override public func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
        return true
    }

    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        textField.style.preferredSize.height = input.height

        return ASInsetLayoutSpec(insets: input.insets, child: textField)
    }
}
