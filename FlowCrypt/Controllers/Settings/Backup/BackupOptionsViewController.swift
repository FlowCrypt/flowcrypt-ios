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
    private var slectedOption: BackupOption = .email { didSet { handleOptionChange() } }

    init(
        decorator: BackupOptionsViewDecoratorType = BackupOptionsViewDecorator(),
        backups: [KeyDetails]
    ) {
        self.decorator = decorator
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

extension BackupOptionsViewController {
    private func handleButtonTap() {
        print("^^ Tap")
    }

    private func handleOptionChange() {
        node.reloadData()
    }
}

extension BackupOptionsViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
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
                        isSelected: self.slectedOption == .download
                    )
                )
            case .email:
                return CheckBoxTextNode(
                    input: self.decorator.checkboxContext(
                        for: .email,
                        isSelected: self.slectedOption == .email
                    )
                )
            case .action:
                return ButtonCellNode(
                    title: self.decorator.buttonText(for: self.slectedOption),
                    insets: self.decorator.insets
                ) { [weak self] in
                    self?.handleButtonTap()
                }
            case .info:
                return BackupCellNode(
                    title: self.decorator.description(for: self.slectedOption),
                    insets: self.decorator.insets
                )
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: false)
        guard let part = Parts(rawValue: indexPath.row) else { return }

        switch part {
        case .email: slectedOption = .email
        case .download: slectedOption = .download
        case .action: handleButtonTap()
        case .info: break
        }
    }
}

// TODO: - Anton
// CheckBoxTextNode.Input for download/email is selected
