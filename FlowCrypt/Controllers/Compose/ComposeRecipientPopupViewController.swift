//
//  ComposeRecipientPopupViewController.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 3/31/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import FlowCryptUI

/**
 * View controller to display recipient popup
 * - User can be redirected here from *ComposeViewController* by tapping on any added recipients
 **/
final class ComposeRecipientPopupViewController: TableNodeViewController {

    enum Parts {
        case nameEmail, divider, copy, copyAll, remove
    }

    var parts: [Parts] {
        return [.nameEmail, .divider, .copy, .copyAll, .divider, .remove]
    }

    private let recipient: ComposeMessageRecipient

    init(recipient: ComposeMessageRecipient) {
        self.recipient = recipient
        super.init(node: TableNode())

        node.delegate = self
        node.dataSource = self
        node.reloadData()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension ComposeRecipientPopupViewController: ASTableDelegate, ASTableDataSource {

    func tableNode(_: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return parts.count
    }

    // swiftlint:disable cyclomatic_complexity
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self
            else { return ASCellNode() }

            let part = self.parts[indexPath.row]
            switch part {
            case .copy, .copyAll, .remove:
                return InfoCellNode(input: .getFromCellType(type: part))
            case .nameEmail:
                return ASCellNode()
            case .divider:
                return DividerCellNode()
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
    }
}

extension InfoCellNode.Input {
    static func getFromCellType(type: ComposeRecipientPopupViewController.Parts) -> InfoCellNode.Input {
        let icon: String = {
            switch type {
            case .remove:
                return "trash"
            case .copy, .copyAll:
                return "copy"
            default:
                return ""
            }
        }()

        return .init(
            attributedText: "compose_recipient_\(type)"
                .localized
                .attributed(.regular(17), color: .mainTextColor),
            image: #imageLiteral(resourceName: icon).tinted(.mainTextColor),
            insets: .side(16),
            backgroundColor: .backgroundColor
        )
    }
}
