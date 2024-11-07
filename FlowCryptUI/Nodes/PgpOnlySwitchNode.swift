//
//  PgpOnlySwitchNode.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 10/31/24
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon

public final class PgpOnlySwitchNode: CellNode {

    let SHOW_PGP_ONLY_KEY = "SHOW_PGP_ONLY_FLAG"

    private lazy var imageNode: ASImageNode = {
        let node = ASImageNode()
        node.image = UIImage(systemName: "lock.shield")?.tinted(.main)
        node.style.preferredSize = CGSize(width: 30, height: 30)
        return node
    }()

    private lazy var toggleNode: SwitchCellNode = {
        let input = SwitchCellNode.Input(
            isOn: UserDefaults.standard.bool(forKey: SHOW_PGP_ONLY_KEY),
            attributedText: "show_only_pgp_messages"
                .localized
                .attributed(.medium(16), color: .textColor),
            accessibilityIdentifier: "aid-toggle-pgp-only-node",
            backgroundColor: .clear,
            switchJustifyContent: .center
        )
        return SwitchCellNode(input: input) { isOn in
            UserDefaults.standard.setValue(isOn, forKey: self.SHOW_PGP_ONLY_KEY)
            NotificationCenter.default.post(name: .reloadThreadList, object: nil)
        }
    }()

    override public init() {
        super.init()
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        toggleNode.style.flexGrow = 1
        toggleNode.style.flexShrink = 1
        return ASInsetLayoutSpec(
            insets: .deviceSpecificTextInsets(top: 16, bottom: 16),
            child: ASStackLayoutSpec.horizontal().then {
                $0.spacing = 10
                $0.alignItems = .center
                $0.justifyContent = .spaceBetween
                $0.children = [imageNode, toggleNode]
            }
        )
    }
}
