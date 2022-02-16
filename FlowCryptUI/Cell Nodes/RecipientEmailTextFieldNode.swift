//
//  RecipientEmailTextFieldNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 10/02/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class RecipientEmailTextFieldNode: TextFieldCellNode, RecipientToggleButtonNode {
    var toggleButtonAction: (() -> Void)?

    lazy var toggleButtonNode: ASButtonNode = {
        createToggleButton()
    }()

    var isToggleButtonRotated = false {
        didSet {
            updateToggleButton(animated: true)
        }
    }

    public init(
        input: TextFieldCellNode.Input,
        action: TextFieldAction? = nil,
        isToggleButtonRotated: Bool,
        toggleButtonAction: (() -> Void)?
    ) {
        super.init(input: input, action: action)

        self.isLowercased = true
        self.isToggleButtonRotated = isToggleButtonRotated
        self.toggleButtonAction = toggleButtonAction
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let textFieldWidth = input.width ?? (constrainedSize.max.width - input.insets.width)
        let textFieldSize = CGSize(width: textFieldWidth, height: input.height)
        let buttonSize = CGSize(width: input.height, height: input.height)

        return createLayout(
            contentNode: textField,
            contentSize: textFieldSize,
            insets: input.insets,
            buttonSize: buttonSize
        )
    }

    func onToggleButtonTap() {
        isToggleButtonRotated.toggle()
        toggleButtonAction?()
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
        return true
    }
}
