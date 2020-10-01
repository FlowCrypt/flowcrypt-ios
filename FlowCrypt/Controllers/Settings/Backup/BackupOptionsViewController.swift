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
    enum BackupOption: Int, CaseIterable {
        case email, download
    }
    
    private enum Parts: Int, CaseIterable {
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
                    input: CheckBoxTextNode.Input.init(
                        title: NSAttributedString(string: "download"),
                        insets: .side(16),
                        preferredSize: CGSize(width: 30, height: 30),
                        checkBoxInput: CheckBoxNode.Input(
                            color: .main,
                            strokeWidth: 2
                        )
                    )
                )
            case .email: return CheckBoxTextNode(
                input: CheckBoxTextNode.Input.init(
                    title: NSAttributedString(string: "email"),
                    insets: .side(16),
                    preferredSize: CGSize(width: 30, height: 30),
                    checkBoxInput: CheckBoxNode.Input(
                        color: .main,
                        strokeWidth: 2
                    )
                )
            )
            case .action: return ButtonCellNode(
                title: NSAttributedString(string: "Button"),
                insets: .side(16)
            ) { [weak self] in
                self?.handleButtonTap()
            }
            case .info:
                return BackupCellNode(
                    title: NSAttributedString(string: "alksfhlah fsalkfhal f afskh "),
                    insets: UIEdgeInsets(top: 8, left: 8, bottom: 16, right: 8)
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
// Button title for selected type
// info for selected type
