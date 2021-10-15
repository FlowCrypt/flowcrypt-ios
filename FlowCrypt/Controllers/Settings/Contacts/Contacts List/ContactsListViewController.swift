//
//  ContactsListViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 22/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI

/**
 * View controller which shows saved user contacts list
 * - User can be redirected here from settings *SettingsViewController*
 * - By tapping on a particular contact, user will be forwarded to *ContactDetailViewController*
 */
final class ContactsListViewController: TableNodeViewController {
    private let decorator: ContactsListDecoratorType
    private let contactsProvider: LocalContactsProviderType
    private var recipients: [RecipientWithPubKeys] = []
    private var selectedIndexPath: IndexPath?

    init(
        decorator: ContactsListDecoratorType = ContactsListDecorator(),
        contactsProvider: LocalContactsProviderType = LocalContactsProvider()
    ) {
        self.decorator = decorator
        self.contactsProvider = contactsProvider
        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchContacts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadContacts()
    }
}

extension ContactsListViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        title = decorator.title
    }

    private func reloadContacts() {
        guard let indexPath = selectedIndexPath else { return }
        fetchContacts()
        node.reloadRows(at: [indexPath], with: .automatic)
        selectedIndexPath = nil
    }

    private func fetchContacts() {
        recipients = contactsProvider.getAllRecipients()
    }
}

extension ContactsListViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        recipients.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }
            return ContactCellNode(
                input: self.decorator.contactNodeInput(with: self.recipients[indexPath.row]),
                action: { [weak self] in
                    self?.handleDeleteButtonTap(with: indexPath)
                }
            ).then {
                $0.accessibilityLabel = "\(indexPath.row)"
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        proceedToContactDetail(with: indexPath)
    }
}

extension ContactsListViewController {
    private func handleDeleteButtonTap(with indexPath: IndexPath) {
        delete(with: .right(indexPath))
    }

    private func proceedToContactDetail(with indexPath: IndexPath) {
        let contactDetailViewController = ContactDetailViewController(
            recipient: recipients[indexPath.row]
        ) { [weak self] action in
            guard case let .delete(contact) = action else {
                assertionFailure("Action is not implemented")
                return
            }
            self?.delete(with: .left(contact))
        }
        selectedIndexPath = indexPath
        navigationController?.pushViewController(contactDetailViewController, animated: true)
    }

    private func delete(with context: Either<RecipientWithPubKeys, IndexPath>) {
        let recipientToRemove: RecipientWithPubKeys
        let indexPathToRemove: IndexPath
        switch context {
        case .left(let recipient):
            recipientToRemove = recipient
            guard let index = recipients.firstIndex(where: { $0 == recipient }) else {
                assertionFailure("Can't find index of the contact")
                return
            }
            indexPathToRemove = IndexPath(row: index, section: 0)
        case .right(let indexPath):
            indexPathToRemove = indexPath
            recipientToRemove = recipients[indexPath.row]
        }

        contactsProvider.remove(recipient: recipientToRemove)
        recipients.remove(at: indexPathToRemove.row)
        node.deleteRows(at: [indexPathToRemove], with: .left)
    }
}
