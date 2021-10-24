//
//  InvalidStorageViewController.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 24.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

final class InvalidStorageViewController: TableNodeViewController {
    private let encryptedStorage: EncryptedStorageType
    private let router: GlobalRouterType

    init(encryptedStorage: EncryptedStorageType, router: GlobalRouterType) {
        self.encryptedStorage = encryptedStorage
        self.router = router
        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "invalid_storage_title".localized

        node.delegate = self
        node.dataSource = self
        node.reloadData()
    }

    private func handleTap() {
        do {
            try encryptedStorage.reset()
            router.proceed()
        } catch {
            showAlert(message: "invalid_storage_reset_error".localized)
        }
    }
}

extension InvalidStorageViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        2
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        {
            if indexPath.row == 0 {
                return KeyTextCellNode(
                    title: "invalid_storage_text".localized.attributed(.regular(12), color: .black),
                    insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
                )
            }

            if indexPath.row == 1 {
                let input = ButtonCellNode.Input(
                    title: "invalid_storage_reset_button".localized.attributed(.bold(16), color: .white),
                    insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
                    color: .red
                )
                return ButtonCellNode(input: input) { [weak self] in
                    self?.handleTap()
                }
            }

            return ASCellNode()
        }
    }
}
