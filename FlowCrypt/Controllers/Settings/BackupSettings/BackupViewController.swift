//
//  BackupViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 22/09/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import FlowCryptUI
import AsyncDisplayKit

final class BackupViewController: ASViewController<TableNode> {
    private enum Parts: Int, CaseIterable {
        case info, action
    }

    private let decorator: BackupViewDecoratorType

    init(
        decorator: BackupViewDecoratorType = BackupViewDecorator()
    ) {
        self.decorator = decorator
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

extension BackupViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        title = decorator.sceneTitle
    }
}

extension BackupViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        0
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
//            guard let self = self, let setting = Settings(rawValue: indexPath.row) else { return ASCellNode() }

            return ASCellNode()
        }
    }
}
