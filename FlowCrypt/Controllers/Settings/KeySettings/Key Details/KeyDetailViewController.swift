//
//  KeyDetailScreen.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class KeyDetailViewController: ASViewController<TableNode> {
    enum Parts: Int, CaseIterable {
        case description, publicInfo, keyDetails, copy, save, privateInfo
    }

    private let pasteboard: UIPasteboard
    private let key: KeySettingsItem
    private let decorator: KeySettingsItemDecoratorType

    init(
        key: KeySettingsItem,
        pasteboard: UIPasteboard = UIPasteboard.general,
        decorator: KeySettingsItemDecoratorType = KeySettingsItemDecorator()
    ) {
        self.key = key
        self.pasteboard = pasteboard
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
    }
}

extension KeyDetailViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else {
                return ASCellNode()
            }

            if part.isDescription {
                return SetupTitleNode(
                    title: self.decorator.attributedTitle(for: part),
                    insets: self.decorator.titleInsets
                )
            } else {
                return ButtonCellNode(
                    title: self.decorator.attributedTitle(for: part),
                    insets: self.decorator.buttonInsets,
                    color: self.decorator.buttonColor(for: part)
                ) { [weak self] in
                    self?.handleTap(on: part)
                }
            }
        }
    }

    private func handleTap(on part: Parts) {
        switch part {
        case .publicInfo:
            let viewController = PublickKeyDetailViewController(text: key.publicKey)
            navigationController?.pushViewController(viewController, animated: true)
        case .copy:
            pasteboard.string = key.publicKey
            showToast("key_settings_detail_copy".localized)
        case .keyDetails:
            let viewController = KeyDetailInfoViewController(
                details: key.details,
                date: key.createdDate,
                user: key.users
            )
            navigationController?.pushViewController(viewController, animated: true)
        case .save:
            let items = [key.publicKey]
            let viewController = UIActivityViewController(
                activityItems: items,
                applicationActivities: nil
            )
            present(viewController, animated: true)
        case .privateInfo:
            showToast("key_settings_detail_show_private".localized)
        case .description:
            break
        }
    }
}
