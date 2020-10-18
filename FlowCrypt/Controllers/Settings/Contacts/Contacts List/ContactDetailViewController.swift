//
//  ContactDetailViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

final class ContactDetailViewController: ASDKViewController<TableNode> {
    typealias ContactDetailAction = (Action) -> Void

    enum Action {
        case delete(_ contact: Contact)
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

extension ContactDetailViewController {
    @objc private final func handleSaveAction() {
        let activityViewController = UIActivityViewController(
            activityItems: [contact.pubKey],
            applicationActivities: nil
        )
        present(activityViewController, animated: true, completion: nil)
    }

    @objc private final func handleCopyAction() {
        UIPasteboard.general.string = contact.pubKey
        showToast("contact_detail_copy".localized)
    }

    @objc private final func handleRemoveAction() {
        navigationController?.popViewController(animated: true) { [weak self] in
            guard let self = self else { return }
            self.action?(.delete(self.contact))
        }
    }
}

extension ContactDetailViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        1
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }
            return ContactDetailNode(input: self.decorator.nodeInput(with: self.contact))
        }
    }
}
