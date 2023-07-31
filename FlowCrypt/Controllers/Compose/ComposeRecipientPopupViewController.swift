//
//  ComposeRecipientPopupViewController.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 3/31/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

@MainActor
protocol ComposeRecipientPopupViewControllerProtocol {
    func removeRecipient(email: String, type: RecipientType)
    func editRecipient(email: String, type: RecipientType)
    func enableRecipientEditing()
}

/**
 * View controller to display recipient popup
 * - User can be redirected here from *ComposeViewController* by tapping on any added recipients
 **/
final class ComposeRecipientPopupViewController: TableNodeViewController {

    enum Parts {
        case nameEmail, divider, copy, edit, remove
    }

    private var parts: [Parts] {
        [.nameEmail, .divider, .copy, .edit, .divider, .remove]
    }

    private let recipient: ComposeMessageRecipient
    let type: RecipientType
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
            guard let self
            else { return ASCellNode() }

            let part = self.parts[indexPath.row]
            switch part {
            case .copy, .remove, .edit:
                return InfoCellNode(input: .getFromCellType(type: part))
            case .nameEmail:
                return ComposeRecipientPopupNameNode(name: self.recipient.name, email: self.recipient.email)
            case .divider:
                return DividerCellNode()
            }
        }
    }

    // swiftlint:enable cyclomatic_complexity

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let part = self.parts[indexPath.row]
        switch part {
        case .remove:
            self.delegate?.removeRecipient(email: recipient.email, type: type)
            self.dismiss(animated: true, completion: nil)
        case .edit:
            self.delegate?.editRecipient(email: recipient.email, type: type)
            self.dismiss(animated: true, completion: nil)
        case .copy:
            UIPasteboard.general.string = recipient.email
            self.dismiss(animated: true, completion: nil)
        default:
            break
        }
        self.delegate?.enableRecipientEditing()
    }
}

extension InfoCellNode.Input {
    static func getFromCellType(type: ComposeRecipientPopupViewController.Parts) -> InfoCellNode.Input {
        let icon: String = {
            switch type {
            case .remove:
                return "trash.slash"
            case .copy:
                return "doc.on.doc"
            case .edit:
                return "pencil.circle"
            default:
                return ""
            }
        }()

        return .init(
            attributedText: "compose_recipient_\(type)"
                .localized
                .attributed(.regular(17), color: .mainTextColor),
            image: UIImage(systemName: icon)?.tinted(.mainTextColor) ?? UIImage(),
            insets: .side(16),
            backgroundColor: .backgroundColor,
            accessibilityIdentifier: "aid-recipient-popup-\(type)-button"
        )
    }
}
