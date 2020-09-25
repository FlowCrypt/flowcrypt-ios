//
//  KeySettingsViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

final class KeySettingsViewController: ASDKViewController<TableNode> {
    private var keys: [KeyDetails] = []
    private let decorator: KeySettingsViewDecoratorType
    private let keyService: KeyServiceType

    init(
        decorator: KeySettingsViewDecorator = KeySettingsViewDecorator(),
        keyService: KeyServiceType = KeyService()
    ) {
        self.decorator = decorator
        self.keyService = keyService
        super.init(node: TableNode())
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "key_settings_title".localized

        node.delegate = self
        node.dataSource = self
        node.reloadData()

        loadKeysFromStorageAndRender()
        setupNavigationBar()
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(handleAddButtonTap)
        )
    }
}

extension KeySettingsViewController {
    private func loadKeysFromStorageAndRender() {
        switch keyService.retrieveKeyDetails() {
        case let .failure(error):
            handleCommon(error: error)
        case let .success(keys):
            self.keys = keys
            node.reloadData()
        }
    }
}

extension KeySettingsViewController {
    @objc private func handleAddButtonTap() {
        navigationController?.pushViewController(ImportKeyViewController(), animated: true)
    }
}
extension KeySettingsViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        keys.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let key = self.keys[safe: indexPath.row] else {
                return ASCellNode()
            }

            let input = KeySettingCellNode.Input(
                title: self.decorator.attributedUsers(key: key),
                subtitle: self.decorator.attributedKeyWords(key: key),
                date: self.decorator.attributedDateCreated(key: key)
            )
            return KeySettingCellNode(with: input)
        }
    }

    func tableNode(_: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        guard let key = keys[safe: indexPath.row] else { return }
        let viewController = KeyDetailViewController(key: key)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
