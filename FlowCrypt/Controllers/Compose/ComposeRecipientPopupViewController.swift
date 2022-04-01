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

@MainActor
protocol ComposeRecipientPopupViewControllerProtocol {
    func removeRecipient(email: String, type: RecipientType)
}
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
    private let type: RecipientType
    var delegate: ComposeRecipientPopupViewControllerProtocol?

    init(
        recipient: ComposeMessageRecipient,
        type: RecipientType
    ) {
        self.recipient = recipient
        self.type = type
        super.init(node: TableNode())

        preferredContentSize = CGSize(width: 300, height: 240)

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
                return ComposeRecipientPopupNameNode(name: self.recipient.name, email: self.recipient.email)
            case .divider:
                return DividerCellNode()
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let part = self.parts[indexPath.row]
        switch part {
        case .remove:
            self.delegate?.removeRecipient(email: recipient.email, type: type)
            self.dismiss(animated: true, completion: nil)
        case .copy, .copyAll:
            self.dismiss(animated: true, completion: nil)
        default:
            break
        }
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
