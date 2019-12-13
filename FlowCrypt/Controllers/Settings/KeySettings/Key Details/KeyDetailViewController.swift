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
        case description, keyDetails, publicInfo, copy, save, privateInfo
    }

    private let key: KeySettingsItem
    private let decorator: KeySettingsItemDecoratorType

    init(
        key: KeySettingsItem,
        decorator: KeySettingsItemDecoratorType = KeySettingsItemDecorator()
    ) {
        self.key = key
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
        case .description:
            break
        case .publicInfo:
            break
        case .copy:
            break
        case .keyDetails:
            break
        case .save:
            break
        case .privateInfo:
            break
        }
    }
}
