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

    enum State {
        case idle
        case backups([KeyDetails])
        case noBackups

        var isAnyBackups: Bool {
            switch self {
            case .backups: return true
            case .idle, .noBackups: return false
            }
        }
    }

    private let decorator: BackupViewDecoratorType
    private let backupProvider: BackupServiceType
    private var state: State = .idle { didSet { updateState() } }

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
        state = .idle
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
            .then { [weak self] keys in
                self?.state = .backups(keys)
            }
            .catch { error in
                // TODO: - Anton handle error
                print("^^ error \(error)")
            }
    }

    private func updateState() {
        DispatchQueue.main.async {
            self.node.reloadData()
        }
    }
}

extension BackupViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        switch state {
        case .backups, .noBackups:
            return Parts.allCases.count
        case .idle:
            return [Parts.info].count
        }
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }

            switch part {
            case .info:
                return BackupCellNode(
                    title: self.decorator.description(for: self.state),
                    insets: UIEdgeInsets.zero
                )
            case .action:
                return ButtonCellNode(
                    title: self.decorator.buttonTitle(for: self.state),
                    insets: self.decorator.buttonInsets
                ) {

                }
            }
        }
    }
}
