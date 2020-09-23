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
    private let backupProvider: BackupServiceType

    init(
        decorator: BackupViewDecoratorType = BackupViewDecorator(),
        backupProvider: BackupServiceType = BackupService.shared
    ) {
        self.decorator = decorator
        self.backupProvider = backupProvider
        super.init(node: TableNode())
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchBackups()
    }
}

extension BackupViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        title = decorator.sceneTitle
    }

    private func fetchBackups() {
        backupProvider.fetchBackups()
            .then { keys in
                print("^^ \(keys.count)")
            }
            .catch { error in
                print("^^ error \(error)")
            }
    }
}

extension BackupViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }

            return ButtonCellNode(
                title: self.decorator.buttonTitle(isAnyBackups: true),
                insets: self.decorator.buttonInsets
            ) {

            }
        }
    }
}
