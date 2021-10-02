//
//  BackupOptionsViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27/09/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import Combine
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

final class BackupOptionsViewController: ASDKViewController<TableNode> {
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
    private let userId: UserId

    private var cancellable: AnyCancellable?

    init(
        decorator: BackupOptionsViewDecoratorType = BackupOptionsViewDecorator(),
        backupService: BackupServiceType = BackupService(),
        backups: [KeyDetails],
        userId: UserId
    ) {
        self.decorator = decorator
        self.backups = backups
        self.backupService = backupService
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
        cancellable = Just(backups)
            .subscribe(on: DispatchQueue.global())
            .myFlatMap(backupToInbox)
            .receive(on: DispatchQueue.main)
            .sinkFuture(receiveValue: { [weak self] _ in
                self?.hideSpinner()
                self?.navigationController?.popToRootViewController(animated: true)
            }, receiveError: { [weak self] error in
                self?.handleCommon(error: error)
            })
    }

    private func backupAsFile() {
        backupService.backupAsFile(keys: backups, for: self)
    }

    private func backupToInbox(_ input: [KeyDetails]) -> AnyPublisher<Void, Error> {
        backupService.backupToInbox(keys: input, for: userId)
    }
}

// MARK: - ASTableDelegate, ASTableDataSource
extension BackupOptionsViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        { [weak self] in
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
