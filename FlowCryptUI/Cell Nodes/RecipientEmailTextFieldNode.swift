//
//  RecipientEmailTextFieldNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 10/02/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class RecipientEmailTextFieldNode: TextFieldCellNode {

    public override init(
        input: TextFieldCellNode.Input,
        action: TextFieldAction? = nil
    ) {
        super.init(input: input, action: action)

        self.isLowercased = true
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
        return true
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        textField.style.flexGrow = 1
        textField.style.minWidth = ASDimensionMake(130)
        textField.style.preferredSize.height = input.height

        return ASInsetLayoutSpec(insets: input.insets, child: textField)
    }
}
