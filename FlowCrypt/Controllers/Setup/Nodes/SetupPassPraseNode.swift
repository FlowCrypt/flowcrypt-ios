//
//  SetupPassPraseNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class SetupPassPraseNode: ASCellNode {
    private let line = ASDisplayNode()
    private let textField = ASEditableTextNode()

    init(_ placeholder: NSAttributedString = SetupStyle.passPrasePlaceholder) {
        super.init()
        automaticallyManagesSubnodes = true
        selectionStyle = .none
        textField.attributedPlaceholderText = placeholder
        textField.delegate = self
        textField.isSecureTextEntry = true
        line.style.flexGrow = 1.0
        line.backgroundColor = .red
        line.style.preferredSize.height = 3
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 32, left: 16, bottom: 16, right: 16),
            child: ASCenterLayoutSpec(
                centeringOptions: .XY,
                sizingOptions: .minimumXY,
                child: ASStackLayoutSpec(
                    direction: .horizontal,
                    spacing: 1,
                    justifyContent: .center,
                    alignItems: .baselineFirst,
                    children: [
                        textField,
                        line
                    ])
            )
        )
    }
}

extension SetupPassPraseNode: ASEditableTextNodeDelegate {
    func editableTextNode(_ editableTextNode: ASEditableTextNode, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text.rangeOfCharacter(from: .newlines) != nil else { return true }
        editableTextNode.resignFirstResponder()
        return false
    }
}
