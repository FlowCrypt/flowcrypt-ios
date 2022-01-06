//
//  KeyDetailScreen.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

/**
 * View controller which shows possible option for the keys, like show it's public part, details, copy or share it.
 * - User can be redirected here from *KeyDetailViewController*
 */
final class KeyDetailViewController: TableNodeViewController {
    enum Parts: Int, CaseIterable {
        case description, publicInfo, keyDetails, copy, save, privateInfo
    }

    private let key: KeyDetails
    private let parts: [Parts]
    private let pasteboard: UIPasteboard
    private let decorator: KeyDetailViewDecorator

    init(
        key: KeyDetails,
        parts: [Parts] = Parts.allCases,
        pasteboard: UIPasteboard = UIPasteboard.general,
        decorator: KeyDetailViewDecorator = KeyDetailViewDecorator()
    ) {
        self.key = key
        self.parts = parts
        self.pasteboard = pasteboard
        self.decorator = decorator
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
    }
}

extension KeyDetailViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        parts.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else {
                return ASCellNode()
            }

            if part.isDescription {
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: self.decorator.attributedTitle(for: part),
                        insets: self.decorator.titleInsets,
                        backgroundColor: .backgroundColor
                    )
                )
            } else {
                let input = ButtonCellNode.Input(
                    title: self.decorator.attributedTitle(for: part),
                    color: self.decorator.buttonColor(for: part)
                )
                return ButtonCellNode(input: input) { [weak self] in
                    self?.handleTap(on: part)
                }
            }
        }
    }

    private func handleTap(on part: Parts) {
        switch part {
        case .publicInfo:
            let viewController = PublicKeyDetailViewController(text: key.public)
            navigationController?.pushViewController(viewController, animated: true)
        case .copy:
            pasteboard.string = key.public
            showToast("key_settings_detail_copy".localized)
        case .keyDetails:
            let viewController = KeyDetailInfoViewController(key: key)
            navigationController?.pushViewController(viewController, animated: true)
        case .save:
            let items = [key.public]
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
