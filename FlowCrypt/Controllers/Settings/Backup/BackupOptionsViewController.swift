//
//  BackupOptionsViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27/09/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import FlowCryptUI
import AsyncDisplayKit

final class BackupOptionsViewController: ASDKViewController<TableNode> {
    private enum Parts: Int, CaseIterable {
        case email, download, action, info
    }

    private let decorator: BackupOptionsViewDecoratorType
    private let backupProvider: BackupServiceType
    private var backups: [KeyDetails] = []

    init(
        decorator: BackupOptionsViewDecoratorType = BackupOptionsViewDecorator(),
        backupProvider: BackupServiceType = BackupService.shared,
        backups: [KeyDetails]
    ) {
        self.decorator = decorator
        self.backupProvider = backupProvider
        self.backups = backups

        super.init(node: TableNode())
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

extension BackupOptionsViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        title = decorator.sceneTitle
    }
}

extension BackupOptionsViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { ASCellNode() }
    }
//        return { [weak self] in
//            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
//
//            switch part {
//            case .info:
//                return BackupCellNode(
//                    title: self.decorator.description(for: self.state),
//                    insets: UIEdgeInsets(top: 8, left: 8, bottom: 16, right: 8)
//                )
//            case .action:
//                return ButtonCellNode(
//                    title: self.decorator.buttonTitle(for: self.state),
//                    insets: self.decorator.buttonInsets
//                ) {
//
//                }
//            }
//        }
//    }
}
