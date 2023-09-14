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
        case alreadyImported
        case differentKeyImported
        case notYetImported
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

    private lazy var publicKeyLabelNode: ASTextNode = {
        let node = ASTextNode()
        node.attributedText = "public_key_for"
            .localizeWithArguments(input.email)
            .attributed(Constants.fontStyle)
        node.accessibilityIdentifier = "aid-public-key-label"
        return node
    }()

    private lazy var fingerprintNode: ASTextNode = {
        let node = ASTextNode()
        node.attributedText = "fingerprint_label_value"
            .localizeWithArguments(input.fingerprint.spaced(every: 4))
            .attributed(Constants.fontStyle)
        node.accessibilityIdentifier = "aid-fingerprint-value"
        return node
    }()

    private lazy var warningLabel: ASTextNode = {
        let node = ASTextNode()
        node.attributedText = "public_key_import_warning"
            .localized
            .attributed(Constants.fontStyle, color: .warningColor)
        node.accessibilityIdentifier = "aid-warning-label"
        return node
    }()

    private lazy var toggleNode: SwitchCellNode = {
        let input = SwitchCellNode.Input(
            isOn: false,
            attributedText: "show_public_key"
                .localized
                .attributed(Constants.fontStyle, color: .textColor),
            accessibilityIdentifier: "aid-toggle-public-key-node",
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
        node.accessibilityIdentifier = "aid-public-key-value"
        return node
    }()

    private lazy var importKeyButtonNode: ASButtonNode = {
        let node = ASButtonNode()
        var title: String
        var isEnabled = true
        var bgColor: UIColor = .warningColor

        switch input.importStatus {
        case .alreadyImported:
            title = "already_imported"
            isEnabled = false
            bgColor = .gray
        case .differentKeyImported:
            title = "update_public_key"
        case .notYetImported:
            title = "import_public_key"
        }

        node.setTitle(title.localized, with: .boldSystemFont(ofSize: 16), with: .white, for: .normal)
        node.accessibilityIdentifier = "aid-import-key-button"
        node.addTarget(self, action: #selector(importKeyButtonTapped), forControlEvents: .touchUpInside)

        node.isEnabled = isEnabled
        node.backgroundColor = bgColor
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

    public var onImportKey: (() -> Void)?

    let input: Input

    public init(input: Input) {
        self.input = input
        super.init()
        backgroundColor = UIColor.colorFor(darkStyle: UIColor(hex: "303030")!, lightStyle: UIColor(hex: "FAFAFA")!)
        addLeftBorder(width: .threadLeftBorderWidth, color: UIColor(hex: "989898"))
    }

    @objc func importKeyButtonTapped() {
        onImportKey?()
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let verticalStack = ASStackLayoutSpec.vertical()
        verticalStack.spacing = 10

        verticalStack.children = [
            publicKeyLabelNode,
            fingerprintNode,
            input.importStatus != .alreadyImported ? warningLabel : nil,
            toggleNode,
            shouldDisplayPublicKey ? publicKeyValueNode : nil,
            importKeyButtonNode
        ].compactMap { $0 }

        return ASInsetLayoutSpec(
            insets: .threadMessageInsets,
            child: verticalStack
        )
    }
}
