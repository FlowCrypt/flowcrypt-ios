//
//  ContactAddNode.swift
//  FlowCryptUI
//
//  Created by Ioan Moldovan on 9/18/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import UIKit

public final class ContactAddNode: CellNode {

    enum Constants {
        static let fontStyle: NSAttributedString.Style = .regular(15)
    }

    private lazy var introduceTextNode: ASTextNode2 = {
        let node = ASTextNode2()
        node.attributedText = "add_contact_introduce"
            .localized
            .attributed(Constants.fontStyle, color: .textColor, alignment: .center)
        node.accessibilityIdentifier = "aid-introduce-label"
        return node
    }()

    private lazy var warningTextNode: ASTextNode2 = {
        let node = ASTextNode2()
        node.attributedText = "add_contact_public_key_import_warning"
            .localized
            .attributed(Constants.fontStyle, color: .warningColor, alignment: .center)
        node.accessibilityIdentifier = "aid-warning-label"
        return node
    }()

    private lazy var importFromFileButton: ASButtonNode = {
        let node = ASButtonNode()
        node.setTitle("load_from_file".localized, with: .boldSystemFont(ofSize: 16), with: .white, for: .normal)
        node.accessibilityIdentifier = "aid-import-from-file-button"
        node.addTarget(self, action: #selector(importFromFileButtonTaped), forControlEvents: .touchUpInside)
        node.backgroundColor = .warningColor
        node.style.flexGrow = 1.0
        node.style.preferredSize.height = 50
        return node
    }()

    private lazy var importFromClipboardButton: ASButtonNode = {
        let node = ASButtonNode()
        node.setTitle("load_from_clipboard".localized, with: .boldSystemFont(ofSize: 16), with: .white, for: .normal)
        node.accessibilityIdentifier = "aid-import-from-clipboard-button"
        node.addTarget(self, action: #selector(importFromClipboardButtonTaped), forControlEvents: .touchUpInside)
        node.backgroundColor = .warningColor
        node.style.flexGrow = 1.0
        node.style.preferredSize.height = 50
        return node
    }()

    public var onImportFromClipboard: (() -> Void)?
    public var onImportFromFile: (() -> Void)?

    override public init() {
        super.init()
    }

    @objc func importFromFileButtonTaped() {
        onImportFromFile?()
    }

    @objc func importFromClipboardButtonTaped() {
        onImportFromClipboard?()
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let spec = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 30,
            justifyContent: .center,
            alignItems: .stretch,
            children: [introduceTextNode, warningTextNode, importFromFileButton, importFromClipboardButton]
        )
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 50, left: 20, bottom: 50, right: 20),
            child: ASCenterLayoutSpec(child: spec)
        )
    }
}
