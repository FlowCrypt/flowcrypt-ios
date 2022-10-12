//
//  InvalidStorageViewController.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 24.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import AsyncDisplayKit

final class InvalidStorageViewController: TableNodeViewController {
    private enum Parts: Int, CaseIterable {
        case screenTitle
        case title
        case description
        case retry
        case reset
    }

    private let error: Error
    private let router: GlobalRouterType

    init(error: Error, router: GlobalRouterType) {
        self.error = error
        self.router = router
        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor

        node.delegate = self
        node.dataSource = self
        node.bounces = false
        node.reloadData()
    }

    private func resetStorage() {
        do {
            try EncryptedStorage.removeStorageFile()
            router.proceed()
        } catch {
            showAlert(message: "invalid_storage_reset_error".localized)
        }
    }

    private func retry() {
        router.proceed()
    }
}

extension InvalidStorageViewController {
    private func createTitleNode(
        title: String,
        style: NSAttributedString.Style = .regular(16)
    ) -> SetupTitleNode {
        .init(
            SetupTitleNode.Input(
                title: title
                    .attributed(
                        style,
                        color: .mainTextColor,
                        alignment: .center
                    ),
                insets: .deviceSpecificInsets(top: 8, bottom: 8),
                backgroundColor: .backgroundColor
            )
        )
    }

    private func createButtonNode(
        title: String,
        backgroundColor: UIColor,
        action: @escaping () -> Void
    ) -> ButtonCellNode {
        .init(
            input: ButtonCellNode.Input(
                title: title
                    .attributed(
                        .bold(16),
                        color: .white,
                        alignment: .center
                    ),
                color: backgroundColor
            ),
            action: action
        )
    }
}

extension InvalidStorageViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_ node: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self, let part = Parts(rawValue: indexPath.row) else {
                return ASCellNode()
            }

            switch part {
            case .screenTitle:
                return self.createTitleNode(
                    title: "invalid_storage_title".localized,
                    style: .bold(18)
                )
            case .title:
                return self.createTitleNode(
                    title: "invalid_storage_text".localized
                )
            case .description:
                return self.createTitleNode(
                    title: self.error.errorMessage
                )
            case .retry:
                return self.createButtonNode(
                    title: "retry_title".localized,
                    backgroundColor: .main,
                    action: { [weak self] in
                        self?.retry()
                    }
                )
            case .reset:
                return self.createButtonNode(
                    title: "invalid_storage_reset_button".localized,
                    backgroundColor: .red,
                    action: { [weak self] in
                        self?.resetStorage()
                    }
                )
            }
        }
    }
}
