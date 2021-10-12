//
//  ContactDetailViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

/**
 * View controller which shows details about a contact and the public key recorded for it
 * - User can be redirected here from settings *ContactsListViewController* by tapping on a particular contact
 */
final class ContactDetailViewController: TableNodeViewController {
    typealias ContactDetailAction = (Action) -> Void

    enum Action {
        case delete(_ contact: Contact)
    }

    private enum Section: Int, CaseIterable {
        case header = 0, keys
    }

    private let decorator: ContactDetailDecoratorType
    private let contact: Contact
    private let action: ContactDetailAction?

    init(
        decorator: ContactDetailDecoratorType = ContactDetailDecorator(),
        contact: Contact,
        action: ContactDetailAction?
    ) {
        self.decorator = decorator
        self.contact = contact
        self.action = action
        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        node.delegate = self
        node.dataSource = self
        title = decorator.title
        setupNavigationBarItems()
    }

    private func setupNavigationBarItems() {
        navigationItem.rightBarButtonItem = NavigationBarItemsView(
            with: [
                .init(image: UIImage(systemName: "trash"), action: (self, #selector(handleRemoveAction)))
            ]
        )
    }
}

extension ContactDetailViewController {
    @objc private final func handleRemoveAction() {
        navigationController?.popViewController(animated: true) { [weak self] in
            guard let self = self else { return }
            self.action?(.delete(self.contact))
        }
    }
}

extension ContactDetailViewController: ASTableDelegate, ASTableDataSource {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        Section.allCases.count
    }

    func tableNode(_: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }

        switch section {
        case .header: return 1
        case .keys: return contact.pubKeys.count
        }
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        { [weak self] in
            guard let self = self, let section = Section(rawValue: indexPath.section)
            else { return ASCellNode() }
            return self.node(for: section, row: indexPath.row)
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }

        switch section {
        case .header:
            return
        case .keys:
            return
        }
    }
}

// MARK: - UI
extension ContactDetailViewController {
    private func node(for section: Section, row: Int) -> ASCellNode {
        switch section {
        case .header:
            return ContactUserCellNode(input: self.decorator.userNodeInput(with: self.contact))
        case .keys:
            return ContactKeyCellNode(
                input: self.decorator.keyNodeInput(with: self.contact.pubKeys[row])
            )
        }
    }
}
