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
        case delete(_ key: PubKey)
    }

    enum Part: Int, CaseIterable {
        case armored = 0, signature, created, checked, expire, longids, fingerprints, algo
    }

    private let decorator: ContactKeyDetailDecorator
    private let pubKey: PubKey
    private let action: ContactKeyDetailAction?

    init(
        decorator: ContactKeyDetailDecorator = ContactKeyDetailDecorator(),
        pubKey: PubKey,
        action: ContactKeyDetailAction?
    ) {
        self.decorator = decorator
        self.pubKey = pubKey
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
                    image: UIImage(named: "share"), accessibilityId: "aid-share-btn"
                ) { [weak self] in self?.handleSaveAction() },
                .init(
                    image: UIImage(named: "copy"), accessibilityId: "aid-copy-btn"
                ) { [weak self] in self?.handleCopyAction() },
                .init(
                    image: UIImage(systemName: "trash"), accessibilityId: "aid-trash-btn"
                ) { [weak self] in self?.handleRemoveAction() }
            ]
        )
    }
}

extension ContactKeyDetailViewController {
    private final func handleSaveAction() {
        let activityViewController = UIActivityViewController(
            activityItems: [pubKey.armored],
            applicationActivities: nil
        )
        activityViewController.popoverPresentationController?.centredPresentation(in: view)
        present(activityViewController, animated: true, completion: nil)
    }

    private final func handleCopyAction() {
        UIPasteboard.general.string = pubKey.armored
        showToast("contact_detail_copy".localized)
    }

    private final func handleRemoveAction() {
        navigationController?.popViewController(animated: true) { [weak self] in
            guard let self else { return }
            self.action?(.delete(self.pubKey))
        }
    }
}

extension ContactKeyDetailViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        Part.allCases.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self, let part = Part(rawValue: indexPath.row) else {
                return ASCellNode()
            }
            return LabelCellNode(
                input: self.decorator.details(
                    for: self.pubKey,
                    part: part
                )
            )
        }
    }
}
