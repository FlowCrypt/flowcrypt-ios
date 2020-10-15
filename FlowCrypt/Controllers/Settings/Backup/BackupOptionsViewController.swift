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
    enum BackupOption: Int, CaseIterable, Equatable {
        case email, download

        var isEmail: Bool {
            switch self {
            case .download: return false
            case .email: return true
            }
        }
    }

    enum Parts: Int, CaseIterable {
        case email, download, action, info
    }

    private let decorator: BackupOptionsViewDecoratorType
    private var backups: [KeyDetails] = []
    private var selectedOption: BackupOption = .email {
        didSet { handleOptionChange() }
    }
    private let attester = AttesterApi()
    private let backupService: BackupServiceType

    init(
        decorator: BackupOptionsViewDecoratorType = BackupOptionsViewDecorator(),
        backupService: BackupServiceType = BackupService.shared,
        backups: [KeyDetails]
    ) {
        self.decorator = decorator
        self.backups = backups
        self.backupService = backupService

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
        backupService.backupToInbox(keys: backups)
            .then(on: .main) { [weak self] in
                self?.hideSpinner()
                self?.navigationController?.popToRootViewController(animated: true)
            }
            .catch(on: .main) { [weak self] error in
                self?.handleCommon(error: error)
            }
    }

    private func backupAsFile() {
        backupService.backupAsFile(keys: backups, for: self)
    }
}

// MARK: - ASTableDelegate, ASTableDataSource
extension BackupOptionsViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }

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
                return ButtonCellNode(
                    title: self.decorator.buttonText(for: self.selectedOption),
                    insets: self.decorator.insets
                ) { [weak self] in
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
