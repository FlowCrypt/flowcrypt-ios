//
//  ContactKeyDetailViewController.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 13/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    
import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI

/**
 * View controller which shows details about a contact and the public key recorded for it
 * - User can be redirected here from settings *ContactsListViewController* by tapping on a particular contact
 */
final class ContactKeyDetailViewController: TableNodeViewController {
    typealias ContactKeyDetailAction = (Action) -> Void

    enum Action {
        case delete(_ key: ContactKey)
    }

    private enum Section: Int, CaseIterable {
        case key = 0, signature, checked, expire, longids, fingerprints, created, algo
    }

    private let decorator: ContactKeyDetailDecoratorType
    private let key: ContactKey
    private let action: ContactKeyDetailAction?

    init(
        decorator: ContactKeyDetailDecoratorType = ContactKeyDetailDecorator(),
        key: ContactKey,
        action: ContactKeyDetailAction?
    ) {
        self.decorator = decorator
        self.key = key
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
                .init(image: UIImage(named: "share"), action: (self, #selector(handleSaveAction))),
                .init(image: UIImage(named: "copy"), action: (self, #selector(handleCopyAction))),
                .init(image: UIImage(named: "trash"), action: (self, #selector(handleRemoveAction)))
            ]
        )
    }
}

extension ContactKeyDetailViewController {
    @objc private final func handleSaveAction() {
        let vc = UIActivityViewController(
            activityItems: [key.key],
            applicationActivities: nil
        )
        present(vc, animated: true, completion: nil)
    }

    @objc private final func handleCopyAction() {
        UIPasteboard.general.string = key.key
        showToast("contact_detail_copy".localized)
    }

    @objc private final func handleRemoveAction() {
        navigationController?.popViewController(animated: true) { [weak self] in
            guard let self = self else { return }
            self.action?(.delete(self.key))
        }
    }
}

extension ContactKeyDetailViewController: ASTableDelegate, ASTableDataSource {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        Section.allCases.count
    }

    func tableNode(_: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        { [weak self] in
            guard let self = self, let section = Section(rawValue: indexPath.section)
            else { return ASCellNode() }
            return self.node(for: section, row: indexPath.row)
        }
    }
}

// MARK: - UI
extension ContactKeyDetailViewController {
    private func node(for section: Section, row: Int) -> ASCellNode {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .medium
        
        switch section {
        case .key:
            return LabelCellNode(title: "Key".attributed(.bold(16)),
                                 text: key.key.attributed(.regular(14)))
        case .signature:
            return LabelCellNode(title: "Signature".attributed(.bold(16)),
                                 text: "Text".attributed(.regular(14)))
        case .checked:
            let checkedString: String = {
                guard let created = key.lastChecked else { return "-" }
                return df.string(from: created)
            }()
            return LabelCellNode(title: "Last fetched".attributed(.bold(16)),
                                 text: checkedString.attributed(.regular(14)))
        case .expire:
            let expireString: String = {
                guard let expires = key.expiresOn else { return "-" }
                return df.string(from: expires)
            }()
            return LabelCellNode(title: "Expires".attributed(.bold(16)),
                                 text: expireString.attributed(.regular(14)))
        case .longids:
            return LabelCellNode(title: "Longids".attributed(.bold(16)),
                                 text: key.longids.joined(separator: ", ").attributed(.regular(14)))
        case .fingerprints:
            return LabelCellNode(title: "Fingerprints".attributed(.bold(16)),
                                 text: key.fingerprints.joined(separator: ", ").attributed(.regular(14)))
        case .created:
            let createdString: String = {
                guard let created = key.created else { return "-" }
                return df.string(from: created)
            }()
            return LabelCellNode(title: "Created".attributed(.bold(16)),
                                 text: createdString.attributed(.regular(14)))
        case .algo:
            let algoString = key.algo?.algorithm ?? "-"
            return LabelCellNode(title: "Algo".attributed(.bold(16)),
                                 text: algoString.attributed(.regular(14)))
        }
    }

}
