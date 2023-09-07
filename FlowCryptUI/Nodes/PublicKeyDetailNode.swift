//
//  PublicKeyDetailNode.swift
//  FlowCryptUI
//
//  Created by Ioan Moldovan on 9/5/23
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import UIKit

public final class PublicKeyDetailNode: CellNode {

    public struct Input {
        let email: String
        let publicKey: String
        let fingerprint: String

        public init(
            email: String,
            publicKey: String,
            fingerprint: String
        ) {
            self.email = email
            self.publicKey = publicKey
            self.fingerprint = fingerprint
        }
    }

    private lazy var publicKeyLabelNode: ASTextNode = {
        let node = ASTextNode()
        node.attributedText = "Public key for \(input.email)".attributed()
        return node
    }()

    private lazy var fingerprintNode: ASTextNode = {
        let node = ASTextNode()
        node.attributedText = "(Fingerprint: \(input.fingerprint)".attributed()
        return node
    }()

    private lazy var toggleNode: SwitchCellNode = {
        let input = SwitchCellNode.Input(
            isOn: true,
            attributedText: "show_public_key"
                .localized
                .attributed(.regular(17), color: .textColor)
        )
        let node = SwitchCellNode(input: input) { isOn in
            print(isOn)
        }
        return node
    }()

    private lazy var publicKeyValueNode: ASTextNode = {
        let node = ASTextNode()
        node.attributedText = input.publicKey.attributed()
        return node
    }()

    private lazy var importKeyButtonNode: ASButtonNode = {
        let node = ASButtonNode()
        node.setTitle("Import public key", with: .boldSystemFont(ofSize: 16), with: .black, for: .normal)
        return node
    }()

    let input: Input

    public init(input: Input) {
        self.input = input
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let verticalStack = ASStackLayoutSpec.vertical()
        verticalStack.spacing = 3
        verticalStack.style.flexShrink = 1.0
        verticalStack.style.flexGrow = 1.0

        verticalStack.children = [publicKeyLabelNode, fingerprintNode, toggleNode, publicKeyValueNode, importKeyButtonNode]

        return verticalStack
    }
}
