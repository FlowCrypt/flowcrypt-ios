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

    private let appContext: AppContextWithUser
    private var keys: [KeyDetails] = []
    private let decorator: KeySettingsViewDecorator
    private let isUsingKeyManager: Bool
    private let keyMethods: KeyMethodsType

    init(
        appContext: AppContextWithUser,
        decorator: KeySettingsViewDecorator = KeySettingsViewDecorator(),
        keyMethods: KeyMethodsType = KeyMethods()
    ) async throws {
        self.appContext = appContext
        self.decorator = decorator
        self.isUsingKeyManager = try await appContext.clientConfigurationService.configuration.isUsingKeyManager
        self.keyMethods = keyMethods
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
        setupNavigationBar()
        loadKeys()
    }

    private func setupNavigationBar() {
        if !isUsingKeyManager {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .add,
                target: self,
                action: #selector(handleAddButtonTap)
            )
            navigationItem.rightBarButtonItem?.accessibilityIdentifier = "aid-add-button"
        }
    }

    private func loadKeys() {
        Task {
            do {
                try await loadKeysFromStorageAndRender()
            } catch {
                showAlert(message: error.errorMessage)
            }
        }
    }
}

extension KeySettingsViewController {
    private func loadKeysFromStorageAndRender() async throws {
        let privateKeys = try appContext.encryptedStorage.getKeypairs(by: appContext.user.email).map(\.private)
        self.keys = try await keyMethods.parseKeys(armored: privateKeys)
        await node.reloadData()
    }
}

extension KeySettingsViewController {
    @objc private func handleAddButtonTap() {
        navigationController?.pushViewController(SetupManuallyImportKeyViewController(appContext: appContext), animated: true)
    }
}

extension KeySettingsViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        keys.isEmpty ? 1 : keys.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }
            if self.keys.isEmpty {
                return EmptyCellNode(input: self.decorator.emptyNodeInput())
            }
            guard let key = self.keys[safe: indexPath.row] else {
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

        var parts = KeyDetailViewController.Part.allCases
        if isUsingKeyManager {
            if let index = parts.firstIndex(where: { $0 == .privateInfo }) {
                parts.remove(at: index)
            }
        }

        let viewController = KeyDetailViewController(key: key, parts: parts)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
