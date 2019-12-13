//
//  KeySettingsViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class KeySettingsViewController: ASViewController<TableNode> {
    private var keys: [KeySettingsItem] = []
    private let decorator: KeySettingsDecoratorType
    private let provider: KeySettingsProviderType
    private let user: String

    init(
        decorator: KeySettingsDecorator = KeySettingsDecorator(),
        provider: KeySettingsProviderType = KeySettingsProvider.shared,
        user: String
    ) {
        self.decorator = decorator
        self.provider = provider
        self.user = user
        super.init(node: TableNode())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "key_settings_title".localized

        node.delegate = self
        node.dataSource = self
        node.reloadData()

        fetchKeys()
    }
}

extension KeySettingsViewController {
    private func fetchKeys() {
        let result = provider.getPublickKeys()
        switch result {
        case let .failure(error): handle(error: error)
        case let .success(keys): handle(fetched: keys)
        }
    }

    private func handle(error: KeySettingsError) {
        // TODO: - Handle possible errors
        switch error {
        case .fetching: break
        case .parsing: break
        }
    }

    private func handle(fetched keys: [KeySettingsItem]) {
        self.keys = keys
        node.reloadData()
    }
}

extension KeySettingsViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        keys.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {

        return { [weak self] in
            guard let self = self, let key = self.keys[safe: indexPath.row] else {
                return ASCellNode()
            }

            let input = KeySettingCellNode.Input(
                title: self.decorator.attributedTitle(for: self.user),
                subtitle: self.decorator.attributedSubTitle(for: key),
                date: self.decorator.attributedDate(for: key)
            )
            return KeySettingCellNode(with: input)
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {

    }
}
