//
//  BackupSelectKeyViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.10.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import Foundation

final class BackupSelectKeyViewController: ASDKViewController<TableNode> {
    private let backupService: BackupServiceType
    private let decorator: BackupSelectKeyDecoratorType
    private var backupsContext: [(KeyDetails, Bool)]
    private let selectedOption: BackupOption
    private let userId: UserId

    init(
        decorator: BackupSelectKeyDecoratorType = BackupSelectKeyDecorator(),
        backupService: BackupServiceType = BackupService.shared,
        selectedOption: BackupOption,
        backups: [KeyDetails],
        userId: UserId
    ) {
        self.decorator = decorator
        // set all selected bu default
        self.backupsContext = backups.map { ($0, true) }
        self.backupService = backupService
        self.selectedOption = selectedOption
        self.userId = userId

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
        if backupsContext.filter({ $0.1 == true }).isEmpty {
            showAlert(message: "backup_select_key_screen_no_selection".localized)
        } else {
            makeBackup()
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

        backupService.backupToInbox(keys: backupsToSave, for: userId)
            .then(on: .main) { [weak self] in
                self?.hideSpinner()
                self?.navigationController?.popToRootViewController(animated: true)
            }
            .catch(on: .main) { [weak self] error in
                self?.handleCommon(error: error)
            }
    }

    private func backupAsFile() {
        backupService.backupAsFile(keys: backupsContext.map(\.0), for: self)
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
