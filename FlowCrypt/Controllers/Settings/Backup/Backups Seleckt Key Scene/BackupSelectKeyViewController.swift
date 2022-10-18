//
//  BackupSelectKeyViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.10.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

final class BackupSelectKeyViewController: TableNodeViewController {

    private let appContext: AppContext
    private let decorator: BackupSelectKeyDecoratorType
    private var backupsContext: [(KeyDetails, Bool)]
    private let selectedOption: BackupOption
    private let userId: UserId

    init(
        appContext: AppContext,
        decorator: BackupSelectKeyDecoratorType = BackupSelectKeyDecorator(),
        selectedOption: BackupOption,
        backups: [KeyDetails],
        userId: UserId
    ) {
        self.decorator = decorator
        // set all selected by default
        self.backupsContext = backups.map { ($0, true) }
        self.selectedOption = selectedOption
        self.userId = userId
        self.appContext = appContext
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
}

// MARK: - Setup
extension BackupSelectKeyViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        title = decorator.sceneTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(handleSave)
        )
        node.reloadData()
    }
}

// MARK: - Actions
extension BackupSelectKeyViewController {
    @objc private func handleSave() {
        if backupsContext.contains(where: { $0.1 == true }) {
            makeBackup()
        } else {
            showAlert(message: "backup_select_key_screen_no_selection".localized)
        }
    }

    private func makeBackup() {
        switch selectedOption {
        case .download:
            backupAsFile()
        case .email:
            backupToInbox()
        }
    }

    private func backupToInbox() {
        showSpinner()
        let backupsToSave = backupsContext
            .filter { $0.1 == true }
            .map(\.0)

        Task {
            do {
                try await appContext.getBackupService().backupToInbox(keys: backupsToSave, for: userId)
                hideSpinner()
                navigationController?.popToRootViewController(animated: true)
            } catch {
                showAlert(message: error.errorMessage)
            }
        }
    }

    private func backupAsFile() {
        do {
            try appContext.getBackupService().backupAsFile(keys: backupsContext.map(\.0), for: self)
        } catch {
            showAlert(message: error.errorMessage)
        }
    }
}

// MARK: - ASTableDelegate, ASTableDataSource
extension BackupSelectKeyViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        backupsContext.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        { [weak self] in
            guard let self = self else { return ASCellNode() }

            return CheckBoxTextNode(
                input: self.decorator.checkboxContext(
                    for: self.backupsContext[indexPath.row].0,
                    isSelected: self.backupsContext[indexPath.row].1
                )
            )
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: false)

        let backup = self.backupsContext[indexPath.row]
        backupsContext[indexPath.row] = (backup.0, !backup.1)
        tableNode.reloadRows(at: [indexPath], with: .fade)
    }
}
