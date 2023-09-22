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
    private let decorator: ContactsListDecorator
    private let localContactsProvider: LocalContactsProviderType
    private var recipients: [RecipientWithSortedPubKeys] = []
    private var selectedIndexPath: IndexPath?
    private let appContext: AppContext
    private lazy var addButton = AddButtonNode(identifier: "aid-add-contact-button") { [weak self] in
        self?.addButtonTap()
    }

    init(
        appContext: AppContext,
        decorator: ContactsListDecorator = ContactsListDecorator()
    ) {
        self.decorator = decorator
        self.appContext = appContext
        self.localContactsProvider = LocalContactsProvider(encryptedStorage: appContext.encryptedStorage)
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        setupAddButton()
    }

    private func addButtonTap() {
        let contactAddViewController = ContactAddViewController(appContext: appContext)
        navigationController?.pushViewController(contactAddViewController, animated: true)
    }
}

extension ContactsListViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        title = decorator.title
        node.addSubnode(addButton)
    }

    private func setupAddButton() {
        let offset: CGFloat = 16

        addButton.frame.origin = CGPoint(
            x: node.bounds.maxX - offset - .addButtonSize,
            y: node.bounds.maxY - offset - .addButtonSize - safeAreaWindowInsets.bottom
        )
    }

    private func reloadContacts() {
        guard let indexPath = selectedIndexPath else { return }
        fetchContacts()
        node.reloadRows(at: [indexPath], with: .automatic)
        selectedIndexPath = nil
    }

    func fetchContacts() {
        Task {
            do {
                self.recipients = try await localContactsProvider.getAllRecipients()
                await self.node.reloadData()
            } catch {
                self.showToast("contacts_screen_load_error".localizeWithArguments(error.localizedDescription))
            }
        }
    }
}

extension ContactsListViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        recipients.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self else { return ASCellNode() }
            let cellNode = ContactCellNode(
                input: self.decorator.contactNodeInput(with: self.recipients[indexPath.row])
            ).then {
                $0.accessibilityLabel = "\(indexPath.row)"
            }
            cellNode.action = { [weak self] in
                // Get actual indexPath as above indexPath would be wrong if user deletes existing rows.
                guard let self, let actualIndexPath = self.node.indexPath(for: cellNode) else {
                    return
                }
                self.delete(contact: self.recipients[actualIndexPath.row])
            }
            return cellNode
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        proceedToContactDetail(with: indexPath)
    }
}

extension ContactsListViewController {

    private func proceedToContactDetail(with indexPath: IndexPath) {
        let contactDetailViewController = ContactDetailViewController(
            appContext: appContext,
            recipient: recipients[indexPath.row]
        ) { [weak self] action in
            guard case let .delete(contact) = action else {
                assertionFailure("Action is not implemented")
                return
            }
            self?.delete(contact: contact)
        }
        selectedIndexPath = indexPath
        navigationController?.pushViewController(contactDetailViewController, animated: true)
    }

    private func delete(contact: RecipientWithSortedPubKeys) {
        guard let index = recipients.firstIndex(where: { $0 == contact }) else {
            assertionFailure("Can't find index of the contact")
            return
        }
        let indexPathToRemove = IndexPath(row: index, section: 0)

        do {
            try localContactsProvider.remove(recipient: contact)
            recipients.remove(at: indexPathToRemove.row)
            node.deleteRows(at: [indexPathToRemove], with: .left)
        } catch {
            showToast("contacts_screen_remove_error".localizeWithArguments(error.localizedDescription))
        }
    }
}
