//
//  KeySettingsViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

/**
 * View controller shows list of user keys
 * - User can be redirected here from settings *SettingsViewController*
 * - User can proceed to importing keys *SetupManuallyImportKeyViewController*
 * - User can see detail information for the key in *KeyDetailViewController*
 */
final class KeySettingsViewController: TableNodeViewController {
    private var keys: [KeyDetails] = []
    private let decorator: KeySettingsViewDecorator
    private let keyService: KeyServiceType
    private let isUsingKeyManager: Bool

    init(
        decorator: KeySettingsViewDecorator = KeySettingsViewDecorator(),
        keyService: KeyServiceType = KeyService(),
        clientConfigurationService: ClientConfigurationServiceType = ClientConfigurationService()
    ) {
        self.decorator = decorator
        self.keyService = keyService
        self.isUsingKeyManager = clientConfigurationService.getSavedForCurrentUser().isUsingKeyManager
        super.init(node: TableNode())
    }

    @available(*, unavailable)
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
        if !isUsingKeyManager {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .add,
                target: self,
                action: #selector(handleAddButtonTap)
            )
        }
    }
}

extension KeySettingsViewController {
    private func loadKeysFromStorageAndRender() {
        switch keyService.getPrvKeyDetails() {
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
        navigationController?.pushViewController(SetupManuallyImportKeyViewController(), animated: true)
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
                title: self.decorator.attributedUsers(with: key),
                subtitle: self.decorator.attributedFingerprints(with: key),
                date: self.decorator.attributedDateCreated(with: key)
            )
            return KeySettingCellNode(with: input)
        }
    }

    func tableNode(_: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        guard let key = keys[safe: indexPath.row] else { return }

        var parts = KeyDetailViewController.Parts.allCases
        if isUsingKeyManager {
            if let index = parts.firstIndex(where: { $0 == .privateInfo }) {
                parts.remove(at: index)
            }
        }

        let viewController = KeyDetailViewController(key: key, parts: parts)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
