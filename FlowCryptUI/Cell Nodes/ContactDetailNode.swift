//
//  ContactDetailNode.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 23/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public final class ContactDetailNode: CellNode {
    public struct Input {
        let user: NSAttributedString
        let ids: NSAttributedString
        let fingerprints: NSAttributedString
        let algoInfo: NSAttributedString?
        let created: NSAttributedString?

        public init(
            user: NSAttributedString,
            ids: NSAttributedString,
            fingerprints: NSAttributedString,
            algoInfo: NSAttributedString?,
            created: NSAttributedString?
        ) {
            self.user = user
            self.ids = ids
            self.fingerprints = fingerprints
            self.algoInfo = algoInfo
            self.created = created
        }
    }

    private let input: Input

    private let userTitleNode = ASTextNode2()
    private let userNode = ASTextNode2()

    private let idsTitleNode = ASTextNode2()
    private let idsNode = ASTextNode2()

    private let fingerprintsTitleNode = ASTextNode2()
    private let fingerprintsNode = ASTextNode2()

    private let algoTitleNode = ASTextNode2()
    private let algoNode = ASTextNode2()

    private let createdTitleNode = ASTextNode2()
    private let createdNode = ASTextNode2()

    public init(input: Input) {
        self.input = input
        userTitleNode.attributedText = "User:".attributed(.bold(16))
        userNode.attributedText = input.user

        idsTitleNode.attributedText = "Longids:".attributed(.bold(16))
        idsNode.attributedText = input.ids

        fingerprintsTitleNode.attributedText = "Fingerprints:".attributed(.bold(16))
        fingerprintsNode.attributedText = input.fingerprints

        algoTitleNode.attributedText = "Algorithm:".attributed(.bold(16))
        algoNode.attributedText = input.algoInfo

        createdTitleNode.attributedText = "Created:".attributed(.bold(16))
        createdNode.attributedText = input.created
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let specs = [
            [userTitleNode, userNode],
            [idsTitleNode, idsNode],
            [fingerprintsTitleNode, fingerprintsNode],
            [algoTitleNode, algoNode],
            [createdTitleNode, createdNode]
            ]
            .map {
                ASStackLayoutSpec(
                    direction: .vertical,
                    spacing: 4,
                    justifyContent: .start,
                    alignItems: .start,
                    children: $0
                )
            }

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
            child: ASStackLayoutSpec(
                direction: .vertical,
                spacing: 12,
                justifyContent: .start,
                alignItems: .start,
                children: specs
            )
        )
    }
}
