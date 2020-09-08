//
//  ContactsListViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 22/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import FlowCryptUI
import AsyncDisplayKit

final class ContactsListViewController: ASViewController<TableNode> {
    private let decorator: ContactsListDecoratorType
    private let contactsProvider: LocalContactsProviderType
    private var contacts: [Contact] = []

    init(
        decorator: ContactsListDecoratorType = ContactsListDecorator(),
        contactsProvider: LocalContactsProviderType = LocalContactsProvider(storage: DataService.shared.storage)
    ) {
        self.decorator = decorator
        self.contactsProvider = contactsProvider
        super.init(node: TableNode())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchContacts()
    }
}

extension ContactsListViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        title = decorator.title
    }

    private func fetchContacts() {
        contacts = contactsProvider.getAllContacts()
    }
}

extension ContactsListViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        contacts.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }
            return ContactCellNode(
                input: self.decorator.contactNodeInput(with: self.contacts[indexPath.row]),
                action: { [weak self] in
                    self?.handleDeleteButtonTap(with: indexPath)
                }
            )
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        proceedToKeyDetail(with: indexPath)
    }
}

extension ContactsListViewController {
    private func handleDeleteButtonTap(with indexPath: IndexPath) {
        contactsProvider.remove(contact: contacts[indexPath.row])
        contacts.remove(at: indexPath.row)
        node.deleteRows(at: [indexPath], with: .left)
    }

    private func proceedToKeyDetail(with indexPath: IndexPath) {
        navigationController?.pushViewController(
            ContactDetailViewController(contact: contacts[indexPath.row]),
            animated: true
        )
    }
}
