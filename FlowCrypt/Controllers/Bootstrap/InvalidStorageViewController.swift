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
            try EncryptedStorage.reset()
            router.proceed()
        } catch {
            showAlert(message: "invalid_storage_reset_error".localized)
        }
    }

    private func retry() {
        router.proceed()
    }
}

extension InvalidStorageViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_ node: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else {
                return ASCellNode()
            }

            let insets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            switch part {
            case .screenTitle:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: "invalid_storage_title".localized
                            .attributed(
                                .bold(18),
                                color: .mainTextColor,
                                alignment: .center
                            ),
                        insets: insets,
                        backgroundColor: .backgroundColor
                    )
                )
            case .title:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: "invalid_storage_text"
                            .localized
                            .attributed(
                                .regular(16),
                                color: .mainTextColor,
                                alignment: .center
                            ),
                        insets: insets,
                        backgroundColor: .backgroundColor
                    )
                )
            case .description:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: self.error.errorMessage.attributed(
                            .regular(16),
                            color: .mainTextColor,
                            alignment: .center
                        ),
                        insets: insets,
                        backgroundColor: .backgroundColor
                    )
                )
            case .retry:
                return ButtonCellNode(
                    input: ButtonCellNode.Input(
                        title: "retry_title"
                            .localized
                            .attributed(
                                .bold(16),
                                color: .white,
                                alignment: .center
                            ),
                        color: .main
                    )
                ) { [weak self] in
                    self?.resetStorage()
                }
            case .reset:
                return ButtonCellNode(
                    input: ButtonCellNode.Input(
                        title: "invalid_storage_reset_button"
                            .localized
                            .attributed(
                                .bold(16),
                                color: .white,
                                alignment: .center
                            ),
                        color: .red
                    )
                ) { [weak self] in
                    self?.resetStorage()
                }
            }
        }
    }
}
