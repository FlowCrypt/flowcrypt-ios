//
//  ContatAddViewController.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 9/18/23
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI

final class ContactAddViewController: TableNodeViewController {
    private let appContext: AppContext
    private let filesManager: FilesManagerType

    init(appContext: AppContext) {
        self.appContext = appContext
        self.filesManager = FilesManager()
        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

// MARK: - ASTableDelegate, ASTableDataSource
extension ContactAddViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func tableNode(_ node: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self else { return ASCellNode() }
            let node = ContactAddNode()
            node.onImportFromFile = {
                Task {
                    await self.importFromFile()
                }
            }
            node.onImportFromClipboard = {
                Task {
                    await self.importFromClipboard()
                }
            }
            return node
        }
    }

    func importFromFile() async {
        await filesManager.selectFromFilesApp(from: self)
    }

    func importFromClipboard() async {
        let data = Data((UIPasteboard.general.string ?? "").utf8)
        await processKeys(for: data)
    }

    func processKeys(for attachmentData: Data) async {
        do {
            let parsedKeys = try await Core.shared.parseKeys(armoredOrBinary: attachmentData)
            if parsedKeys.keyDetails.isEmpty {
                showAlert(message: "no_pubkeys_found".localized)
                return
            }
            let viewController = ContactPublicKeyListViewController(appContext: appContext, keyDetailsList: parsedKeys.keyDetails)
            navigationController?.pushViewController(viewController, animated: true)
        } catch {
            showAlert(message: error.errorMessage)
        }
    }
}

extension ContactAddViewController: FilesManagerPresenter {}

// MARK: - UI
extension ContactAddViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
    }
}

// MARK: - UIDocumentPickerDelegate
extension ContactAddViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileUrl = urls.first,
              let attachment = MessageAttachment(fileURL: fileUrl),
              let attachmentData = attachment.data
        else {
            showAlert(message: "files_picking_files_error_message".localized)
            return
        }
        Task {
            await processKeys(for: attachmentData)
        }
    }
}
