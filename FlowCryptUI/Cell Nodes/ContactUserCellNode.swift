//
//  ContactUserCellNode.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 23/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class ContactUserCellNode: CellNode {
    public struct Input {
        let user: NSAttributedString

        public init(user: NSAttributedString) {
            self.user = user
        }
    }

    private let input: Input

    private let userTitleNode = ASTextNode2()
    private let userNode = ASTextNode2()

    public init(input: Input) {
        self.input = input
        userTitleNode.attributedText = "contacts_user".localized
            .attributed(.bold(16))
        userTitleNode.accessibilityIdentifier = "aid-user-label"
        userNode.attributedText = input.user
        userNode.accessibilityIdentifier = "aid-user-email"
    }

    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: .deviceSpecificTextInsets(top: 8, bottom: 8),
            child: ASStackLayoutSpec(
                direction: .vertical,
                spacing: 4,
                justifyContent: .start,
                alignItems: .start,
                children: [userTitleNode, userNode]
            )
        )
    }
}
