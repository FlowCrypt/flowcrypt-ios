//
//  ContactPublicKeyListViewController.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 9/18/23
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI

final class ContactPublicKeyListViewController: TableNodeViewController {
    private let appContext: AppContext
    var keyDetailsList: [KeyDetails] = []
    let localContactsProvider: LocalContactsProviderType

    init(appContext: AppContext, keyDetailsList: [KeyDetails]) {
        self.appContext = appContext
        self.localContactsProvider = LocalContactsProvider(
            encryptedStorage: appContext.encryptedStorage
        )
        self.keyDetailsList = keyDetailsList
        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

// MARK: - ASTableDelegate, ASTableDataSource
extension ContactPublicKeyListViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        return keyDetailsList.count
    }

    func tableNode(_ node: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self else { return ASCellNode() }
            let keyDetails = keyDetailsList[indexPath.row]
            let node = PublicKeyDetailNode(
                input: ThreadDetailsViewController.getPublicKeyDetailInput(
                    for: keyDetails,
                    localContactsProvider: localContactsProvider
                )
            )
            node.onImportKey = {
                self.importPublicKey(indexPath: indexPath, keyDetails: keyDetails)
            }
            return node
        }
    }

    private func importPublicKey(indexPath: IndexPath, keyDetails: KeyDetails) {
        guard let email = keyDetails.pgpUserEmails.first else {
            return
        }
        try? localContactsProvider.updateKey(for: email, pubKey: .init(keyDetails: keyDetails))
        node.reloadRows(at: [indexPath], with: .automatic)
        reloadContactList()
    }

    private func reloadContactList() {
        if let contactsVC = navigationController?.viewControllers.first(
            where: { $0 is ContactsListViewController }
        ) as? ContactsListViewController {
            contactsVC.fetchContacts()
        }
    }
}

// MARK: - UI
extension ContactPublicKeyListViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
    }
}
