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

    private let type: String
    private let hasRecipients: Bool
    lazy var textNode: ASTextNode2 = {
        createNodeLabel(type: type, isEmpty: hasRecipients)
    }()

    var isToggleButtonRotated = false {
        didSet {
            updateToggleButton(animated: true)
        }
    }

    public init(
        input: TextFieldCellNode.Input,
        hasRecipients: Bool,
        type: String,
        action: TextFieldAction? = nil,
        isToggleButtonRotated: Bool,
        toggleButtonAction: (() -> Void)?
    ) {
        self.type = type
        self.hasRecipients = hasRecipients
        super.init(input: input, action: action)

        self.isLowercased = true
        self.isToggleButtonRotated = isToggleButtonRotated
        self.toggleButtonAction = toggleButtonAction
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let textFieldWidth = input.width ?? (constrainedSize.max.width - input.insets.width)
        let textFieldSize = CGSize(width: textFieldWidth, height: input.height)
        let buttonSize = CGSize(width: input.height, height: input.height)

        let textNodeStack = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0), child: textNode)

        return createLayout(
            contentNode: textField,
            textNodeStack: textNodeStack,
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
