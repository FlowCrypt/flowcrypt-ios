//
//  ContactDetailViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI

/**
 * View controller which shows details about a contact and lists public keys recorded for it
 * - User can be redirected here from settings *ContactsListViewController* by tapping on a particular contact
 */
final class ContactDetailViewController: TableNodeViewController {
    typealias ContactDetailAction = (Action) -> Void

    enum Action {
        case delete(_ recipient: RecipientWithSortedPubKeys)
    }

    private enum Section: Int, CaseIterable {
        case header = 0, keys
    }

    private let decorator: ContactDetailDecorator
    private let contactsProvider: LocalContactsProviderType
    private var recipient: RecipientWithSortedPubKeys
    private let action: ContactDetailAction?

    init(
        appContext: AppContext,
        decorator: ContactDetailDecorator = ContactDetailDecorator(),
        recipient: RecipientWithSortedPubKeys,
        action: ContactDetailAction?
    ) {
        self.decorator = decorator
        self.contactsProvider = LocalContactsProvider(encryptedStorage: appContext.encryptedStorage)
        self.recipient = recipient
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
                .init(
                    image: UIImage(systemName: "trash"),
                    accessibilityId: "aid-trash-button"
                ) { [weak self] in
                    self?.handleRemoveAction()
                }
            ]
        )
    }
}

extension ContactDetailViewController {
    @objc private final func handleRemoveAction() {
        navigationController?.popViewController(animated: true) { [weak self] in
            guard let self else { return }
            self.action?(.delete(self.recipient))
        }
    }

    private func delete(with context: Either<PubKey, IndexPath>) {
        let keyToRemove: PubKey
        let indexPathToRemove: IndexPath
        switch context {
        case let .left(key):
            keyToRemove = key
            guard let index = recipient.pubKeys.firstIndex(where: { $0 == key }) else {
                assertionFailure("Can't find index of the contact")
                return
            }
            indexPathToRemove = IndexPath(row: index, section: 1)
        case let .right(indexPath):
            indexPathToRemove = indexPath
            keyToRemove = recipient.pubKeys[indexPath.row]
        }

        recipient.remove(pubKey: keyToRemove)
        if let fingerprint = keyToRemove.fingerprint, fingerprint.isNotEmpty {
            do {
                try contactsProvider.removePubKey(with: fingerprint, for: recipient.email)
            } catch {
                showToast("contact_detail_remove_public_key_error".localizeWithArguments(error.localizedDescription))
            }
        }
        node.deleteRows(at: [indexPathToRemove], with: .left)
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
        case .keys: return recipient.pubKeys.count
        }
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        { [weak self] in
            guard let self, let section = Section(rawValue: indexPath.section)
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
            let pubKey = recipient.pubKeys[indexPath.row]
            let contactKeyDetailViewController = ContactKeyDetailViewController(pubKey: pubKey) { [weak self] action in
                guard case let .delete(key) = action else {
                    assertionFailure("Action is not implemented")
                    return
                }
                self?.delete(with: .left(key))
            }

            navigationController?.pushViewController(contactKeyDetailViewController, animated: true)
        }
    }
}

// MARK: - UI
extension ContactDetailViewController {
    private func node(for section: Section, row: Int) -> ASCellNode {
        switch section {
        case .header:
            return ContactUserCellNode(input: decorator.userNodeInput(with: recipient))
        case .keys:
            return ContactKeyCellNode(
                input: decorator.keyNodeInput(with: recipient.pubKeys[row])
            )
        }
    }
}
