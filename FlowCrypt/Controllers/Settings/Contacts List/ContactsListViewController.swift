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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *) else { return }
        node.reloadData()
    }
}

extension ContactsListViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
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
                title: NSAttributedString(string: self.contacts[indexPath.row].email),
                insets: .zero
            )
        }
    }
}
