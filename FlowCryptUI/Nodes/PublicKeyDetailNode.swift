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

    public enum PublicKeyImportStatus {
        case imported
        case importedDifferent
        case notImported
    }

    public struct Input {
        let email: String
        let publicKey: String
        let fingerprint: String
        let importStatus: PublicKeyImportStatus

        public init(
            email: String,
            publicKey: String,
            fingerprint: String,
            importStatus: PublicKeyImportStatus
        ) {
            self.email = email
            self.publicKey = publicKey
            self.fingerprint = fingerprint
            self.importStatus = importStatus
        }
    }

    enum Constants {
        static let fontStyle: NSAttributedString.Style = .regular(15)
    }

    private lazy var leftBorder = getThreadDetailLeftBorder(color: UIColor(hex: "989898"))

    private lazy var publicKeyLabelNode: ASTextNode = {
        let node = ASTextNode()
        node.attributedText = "public_key_for".localizeWithArguments(input.email).attributed(Constants.fontStyle)
        return node
    }()

    private lazy var fingerprintNode: ASTextNode = {
        let node = ASTextNode()
        node.attributedText = "fingerprint_label_value".localizeWithArguments(input.fingerprint).attributed(Constants.fontStyle)
        return node
    }()

    private lazy var warningLabel: ASTextNode = {
        let node = ASTextNode()
        node.attributedText = "public_key_import_warning".localized.attributed(Constants.fontStyle, color: .warningColor)
        return node
    }()

    private lazy var toggleNode: SwitchCellNode = {
        let input = SwitchCellNode.Input(
            isOn: false,
            attributedText: "show_public_key"
                .localized
                .attributed(Constants.fontStyle, color: .textColor),
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
        node.attributedText = input.publicKey.attributed(Constants.fontStyle, color: .main)
        return node
    }()

    private lazy var importKeyButtonNode: ASButtonNode = {
        let node = ASButtonNode()
        var title: String
        switch input.importStatus {
        case .imported:
            title = "already_imported"
        case .importedDifferent:
            title = "update_public_key"
        case .notImported:
            title = "import_public_key"
        }
        node.setTitle(title.localized, with: .boldSystemFont(ofSize: 16), with: .white, for: .normal)
        node.isEnabled = false
        if input.importStatus == .imported {
            node.isEnabled = false
            node.backgroundColor = .gray
        } else {
            node.backgroundColor = .warningColor
        }
        node.style.flexGrow = 1.0
        node.style.flexShrink = 1.0
        node.style.preferredSize.height = 40
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

        verticalStack.children = [
            publicKeyLabelNode,
            fingerprintNode,
            input.importStatus != .imported ? warningLabel : nil,
            toggleNode,
            shouldDisplayPublicKey ? publicKeyValueNode : nil,
            importKeyButtonNode
        ].compactMap { $0 }

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
