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

    private lazy var leftBorder = getThreadDetailLeftBorder(color: UIColor(hex: "989898"))

    private lazy var publicKeyLabelNode: ASTextNode = {
        let node = ASTextNode()
        node.attributedText = "public_key_for".localizeWithArguments(input.email).attributed()
        return node
    }()

    private lazy var fingerprintNode: ASTextNode = {
        let node = ASTextNode()
        node.attributedText = "fingerprint_label_value".localizeWithArguments(input.fingerprint).attributed()
        return node
    }()

    private lazy var toggleNode: SwitchCellNode = {
        let input = SwitchCellNode.Input(
            isOn: false,
            attributedText: "show_public_key"
                .localized
                .attributed(.regular(17), color: .textColor),
            backgroundColor: .clear,
            switchJustifyContent: .center
        )
        let node = SwitchCellNode(input: input) { isOn in
            self.shouldDisplayPublicKey = isOn
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
        node.setTitle("import_public_key", with: .boldSystemFont(ofSize: 16), with: .black, for: .normal)
        return node
    }()

    var shouldDisplayPublicKey = false {
        didSet {
            setNeedsLayout()
        }
    }

    let input: Input

    public init(input: Input) {
        self.input = input
        super.init()
        backgroundColor = UIColor(hex: "FAFAFA")
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let verticalStack = ASStackLayoutSpec.vertical()
        verticalStack.spacing = 3
        verticalStack.style.flexShrink = 1.0
        verticalStack.style.flexGrow = 1.0

        verticalStack.children = [publicKeyLabelNode, fingerprintNode, toggleNode, importKeyButtonNode]

        if shouldDisplayPublicKey {
            verticalStack.children?.insert(publicKeyValueNode, at: 3)
        }
        let mainLayout = ASInsetLayoutSpec(
            insets: .deviceSpecificTextInsets(top: 15, bottom: 15),
            child: verticalStack
        )
        mainLayout.style.flexGrow = 1.0
        mainLayout.style.flexShrink = 1.0
        return ASInsetLayoutSpec(
            insets: .threadMessageInsets,
            child: ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 0,
                justifyContent: .spaceBetween,
                alignItems: .stretch,
                children: [leftBorder, mainLayout]
            )
        )
    }
}
