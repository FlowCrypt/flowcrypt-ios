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
    enum Part: Int, CaseIterable {
        case description, publicInfo, keyDetails, copy, save, privateInfo
    }

    private let key: KeyDetails
    private let parts: [Part]
    private let pasteboard: UIPasteboard
    private let decorator: KeyDetailViewDecorator

    init(
        key: KeyDetails,
        parts: [Part] = Part.allCases,
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
        return { [weak self] in
            guard let self, let part = Part(rawValue: indexPath.row) else {
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
                let buttonCellNode = ButtonCellNode(input: input) { [weak self] in
                    self?.handleTap(on: part)
                }
                buttonCellNode.accessibilityIdentifier = self.decorator.identifier(for: part)
                return buttonCellNode
            }
        }
    }

    private func handleTap(on part: Part) {
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
            let activityViewController = UIActivityViewController(
                activityItems: items,
                applicationActivities: nil
            )
            activityViewController.popoverPresentationController?.centredPresentation(in: view)

            present(activityViewController, animated: true)
        case .privateInfo:
            showToast("key_settings_detail_show_private".localized)
        case .description:
            break
        }
    }
}
