//
//  BackupOptionsViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27/09/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

enum BackupOption: Int, CaseIterable, Equatable {
    case email, download

    var isEmail: Bool {
        switch self {
        case .download: return false
        case .email: return true
        }
    }
}

@MainActor
final class BackupOptionsViewController: TableNodeViewController {
    enum Parts: Int, CaseIterable {
        case email, download, action, info
    }

    private let decorator: BackupOptionsViewDecoratorType
    private var backups: [KeyDetails] = []
    private var selectedOption: BackupOption = .email {
        didSet { handleOptionChange() }
    }

    private let userId: UserId
    private let appContext: AppContext

    init(
        appContext: AppContext,
        decorator: BackupOptionsViewDecoratorType = BackupOptionsViewDecorator(),
        backups: [KeyDetails],
        userId: UserId
    ) {
        self.appContext = appContext
        self.decorator = decorator
        self.backups = backups
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
extension BackupOptionsViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        title = decorator.sceneTitle
    }
}

// MARK: - Actions
extension BackupOptionsViewController {
    private func handleOptionChange() {
        node.reloadData()
    }

    private func handleButtonTap() {
        if backups.count > 1 {
            proceedToSelectBackupsScreen()
        } else {
            makeBackup()
        }
    }

    private func proceedToSelectBackupsScreen() {
        navigationController?.pushViewController(
            BackupSelectKeyViewController(
                appContext: appContext,
                selectedOption: selectedOption,
                backups: backups,
                userId: userId
            ),
            animated: true
        )
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

        Task {
            do {
                try await appContext.getBackupService().backupToInbox(keys: backups, for: userId)
                hideSpinner()
                navigationController?.popToRootViewController(animated: true)
            } catch {
                showAlert(message: error.errorMessage)
            }
        }
    }

    private func backupAsFile() {
        do {
            try appContext.getBackupService().backupAsFile(keys: backups, for: self)
        } catch {
            showAlert(message: error.errorMessage)
        }
    }
}

// MARK: - ASTableDelegate, ASTableDataSource
extension BackupOptionsViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        { [weak self] in
            guard let self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }

            switch part {
            case .download:
                return CheckBoxTextNode(
                    input: self.decorator.checkboxContext(
                        for: .download,
                        isSelected: self.selectedOption == .download
                    )
                )
            case .email:
                return CheckBoxTextNode(
                    input: self.decorator.checkboxContext(
                        for: .email,
                        isSelected: self.selectedOption == .email
                    )
                )
            case .action:
                let input = ButtonCellNode.Input(
                    title: self.decorator.buttonText(for: self.selectedOption)
                )

                return ButtonCellNode(input: input) { [weak self] in
                    self?.handleButtonTap()
                }
            case .info:
                return BackupCellNode(
                    title: self.decorator.description(for: self.selectedOption),
                    insets: self.decorator.insets
                )
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: false)
        guard let part = Parts(rawValue: indexPath.row) else { return }

        switch part {
        case .email: selectedOption = .email
        case .download: selectedOption = .download
        case .action: handleButtonTap()
        case .info: break
        }
    }
}
