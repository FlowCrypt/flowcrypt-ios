//
//  BackupViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 22/09/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

final class BackupViewController: TableNodeViewController {
    private enum Parts: Int, CaseIterable {
        case info, action
    }

    enum State {
        case idle
        case backups([KeyDetails])
        case noBackups

        var hasAnyBackups: Bool {
            switch self {
            case .backups: return true
            case .idle, .noBackups: return false
            }
        }

        var backups: [KeyDetails] {
            switch self {
            case let .backups(value): return value
            default: return []
            }
        }
    }

    private let appContext: AppContextWithUser
    private let decorator: BackupViewDecorator
    private var state: State = .idle { didSet { updateState() } }

    init(
        appContext: AppContextWithUser,
        decorator: BackupViewDecorator = BackupViewDecorator()
    ) {
        self.appContext = appContext
        self.decorator = decorator
        super.init(node: TableNode())
    }

    @available(*, unavailable)
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
        Task {
            do {
                let keys = try await appContext.getBackupService().fetchBackupsFromInbox(for: appContext.userId)
                state = keys.isEmpty
                    ? .noBackups
                    : .backups(keys)
            } catch {
                showAlert(message: error.errorMessage)
            }
        }
    }

    private func updateState() {
        node.reloadData()
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

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let nodeHeight = tableNode.frame.size.height
            - (navigationController?.navigationBar.frame.size.height ?? 0.0)
            - safeAreaWindowInsets.top
            - safeAreaWindowInsets.bottom
        let height = nodeHeight / 2 - 200

        return { [weak self] in
            guard let self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }

            switch part {
            case .info:
                return BackupCellNode(
                    title: self.decorator.description(for: self.state),
                    insets: UIEdgeInsets(top: height, left: 8, bottom: 16, right: 8)
                )
            case .action:
                let input = ButtonCellNode.Input(
                    title: self.decorator.buttonTitle(for: self.state)
                )
                return ButtonCellNode(input: input) { [weak self] in
                    self?.proceedToBackupOptionsScreen()
                }
            }
        }
    }

    private func proceedToBackupOptionsScreen() {
        let optionsScreen = BackupOptionsViewController(
            appContext: appContext,
            backups: state.backups,
            userId: appContext.userId
        )
        navigationController?.pushViewController(optionsScreen, animated: true)
    }
}
