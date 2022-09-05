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
        let fingerprint: NSAttributedString
        let createdAt: NSAttributedString
        let expires: NSAttributedString

        public init(
            fingerprint: NSAttributedString,
            createdAt: NSAttributedString,
            expires: NSAttributedString
        ) {
            self.fingerprint = fingerprint
            self.createdAt = createdAt
            self.expires = expires
        }
    }

    private let fingerprintTitleNode = ASTextNode2()
    private let fingerprintNode = ASTextNode2()

    private let createdAtTitleNode = ASTextNode2()
    private let createdAtNode = ASTextNode2()

    private let expiresTitleNode = ASTextNode2()
    private let expiresNode = ASTextNode2()

    private let borderNode = ASDisplayNode()

    private let input: Input

    public init(input: Input) {
        self.input = input

        super.init()

        fingerprintTitleNode.attributedText = "contacts_fingerprint".localized
            .attributed(.bold(16))
        fingerprintTitleNode.accessibilityIdentifier = "aid-fingerprint-label"
        fingerprintNode.attributedText = input.fingerprint
        fingerprintNode.accessibilityIdentifier = "aid-fingerprint-value"

        createdAtTitleNode.attributedText = "contacts_created".localized
            .attributed(.bold(16))
        createdAtTitleNode.accessibilityIdentifier = "aid-created-at-label"
        createdAtNode.attributedText = input.createdAt
        createdAtNode.accessibilityIdentifier = "aid-created-at-value"

        expiresTitleNode.attributedText = "contacts_expires".localized
            .attributed(.bold(16))
        expiresTitleNode.accessibilityIdentifier = "aid-expires-label"
        expiresNode.attributedText = input.expires
        expiresNode.accessibilityIdentifier = "aid-expires-value"

        borderNode.borderWidth = 1.0
        borderNode.cornerRadius = 8.0
        borderNode.borderColor = UIColor.lightGray.cgColor
        borderNode.isUserInteractionEnabled = false
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let specs = [
            [fingerprintTitleNode, fingerprintNode],
            [createdAtTitleNode, createdAtNode],
            [expiresTitleNode, expiresNode]
        ].map {
            ASStackLayoutSpec(
                direction: .vertical,
                spacing: 4,
                justifyContent: .start,
                alignItems: .start,
                children: $0
            )
        }

        let stack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 8,
            justifyContent: .start,
            alignItems: .start,
            children: specs
        )

        let borderInset = UIEdgeInsets.deviceSpecificTextInsets(top: 8, bottom: 8)

        let resultSpec = ASInsetLayoutSpec(
            insets: UIEdgeInsets(
                top: 10 + borderInset.top,
                left: 12 + borderInset.left,
                bottom: 10 + borderInset.bottom,
                right: 12 + borderInset.right
            ),
            child: stack
        )

        return ASOverlayLayoutSpec(
            child: resultSpec,
            overlay: ASInsetLayoutSpec(
                insets: borderInset,
                child: borderNode
            )
        )
    }
}
