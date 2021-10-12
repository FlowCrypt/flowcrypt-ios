//
//  ContactKeyCellNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 11/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    

import AsyncDisplayKit
import Foundation

public final class ContactKeyCellNode: CellNode {
    public struct Input {
        let fingerprint: NSAttributedString?
        let createdAt: NSAttributedString?
        let expires: NSAttributedString

        public init(
            fingerprint: NSAttributedString?,
            createdAt: NSAttributedString?,
            expires: NSAttributedString
        ) {
            self.fingerprint = fingerprint
            self.createdAt = createdAt
            self.expires = expires
        }
    }

    private let fingerprintNode = ASTextNode2()
    private let createdAtNode = ASTextNode2()
    private let expiresNode = ASTextNode2()

    private let input: Input

    public init(input: Input) {
        self.input = input

        super.init()

        fingerprintNode.attributedText = input.fingerprint
        createdAtNode.attributedText = input.createdAt
        expiresNode.attributedText = input.expires
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
            child: ASStackLayoutSpec(
                direction: .vertical,
                spacing: 8,
                justifyContent: .start,
                alignItems: .start,
                children: [fingerprintNode, createdAtNode, expiresNode]
            )
        )
    }
}
