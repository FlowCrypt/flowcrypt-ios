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
 * View controller which shows details about contact's public key
 * - User can be redirected here from *ContactDetailViewController* by tapping on a particular key
 */
final class ContactKeyDetailViewController: TableNodeViewController {
    typealias ContactKeyDetailAction = (Action) -> Void

    enum Action {
        case delete(_ key: ContactKey)
    }

    enum Part: Int, CaseIterable {
        case key = 0, signature, created, checked, expire, longids, fingerprints, algo
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
    func tableNode(_: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        Part.allCases.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        { [weak self] in
            guard let self = self, let part = Part(rawValue: indexPath.row)
            else { return ASCellNode() }
            return self.node(for: part)
        }
    }
}

// MARK: - UI
extension ContactKeyDetailViewController {
    private func node(for part: Part) -> ASCellNode {
        LabelCellNode(title: decorator.attributedTitle(for: part),
                      text: content(for: part).attributed(.regular(14)))
    }

    private func content(for part: Part) -> String {
        switch part {
        case .key:
            return key.key
        case .signature:
            return string(from: key.lastSig)
        case .created:
            return string(from: key.created)
        case .checked:
            return string(from: key.lastChecked)
        case .expire:
            return string(from: key.expiresOn)
        case .longids:
            return key.longids.joined(separator: ", ")
        case .fingerprints:
            return key.fingerprints.joined(separator: ", ")
        case .algo:
            return key.algo?.algorithm ?? "-"
        }
    }

    private func string(from date: Date?) -> String {
        guard let date = date else { return "-" }

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .medium
        return df.string(from: date)
    }
}
