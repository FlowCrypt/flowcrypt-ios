//
//  KeySettingsViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

final class KeySettingsViewController: ASViewController<TableNode> {
    private var keys: [KeyDetails] = []
    private let decorator: KeySettingsDecoratorType

    init(
        decorator: KeySettingsDecorator = KeySettingsDecorator()
    ) {
        self.decorator = decorator
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

        loadKeysFromStorageAndRender()
    }
}

extension KeySettingsViewController {
    private func loadKeysFromStorageAndRender() {
        guard let keys = DataManager.shared.keys() else {
            return showAlert(message: "Could not retrieve keys from DataManager. Please restart the app and try again.")
        }
        let keyDetailsArr = keys.compactMap { (privateKeys: PrvKeyInfo) -> [KeyDetails]? in
            let parsedKey = try? Core.shared.parseKeys(armoredOrBinary: privateKeys.private.data())
            return parsedKey?.keyDetails
        }.flatMap { $0 }
        guard keyDetailsArr.count == keys.count else {
            return showAlert(message: "Could not parse keys from storage. Please reinstall the app.")
        }
        self.keys = keyDetailsArr
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
                title: self.decorator.attributedUsers(key: key),
                subtitle: self.decorator.attributedKeyWords(key: key),
                date: self.decorator.attributedDateCreated(key: key)
            )
            return KeySettingCellNode(with: input)
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        guard let key = keys[safe: indexPath.row] else { return }
        let viewController = KeyDetailViewController(key: key)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
