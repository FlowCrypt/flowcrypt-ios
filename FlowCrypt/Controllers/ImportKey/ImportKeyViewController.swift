//
//  ImportKeyViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 14.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class ImportKeyViewController: ASViewController<TableNode> {
    private enum Parts: Int, CaseIterable {
        case title, fileImport, pasteBoardImport
    }

    private let decorator: ImportKeyDecoratorType
    private let pasteboard: UIPasteboard

    init(
        decorator: ImportKeyDecoratorType = ImportKeyDecorator(),
        pasteboard: UIPasteboard = UIPasteboard.general
    ) {
        self.pasteboard = pasteboard
        self.decorator = decorator
        super.init(node: TableNode())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.barStyle = .black
    }

    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        title = decorator.sceneTitle
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension ImportKeyViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .title:
                return SetupTitleNode(
                    title: self.decorator.title,
                    insets: self.decorator.titleInsets
                )
            case .fileImport:
                return SetupButtonNode(
                    title: self.decorator.fileImportTitle,
                    insets: self.decorator.buttonInsets
                ) { [weak self] in
                    self?.proceedToKeyImportFromFile()
                }
            case .pasteBoardImport:
                return SetupButtonNode(
                    title: self.decorator.pasteBoardTitle,
                    insets: self.decorator.buttonInsets
                ) { [weak self] in
                    self?.proceedToKeyImportFromPasteboard()
                }
                .then {
                    $0.isButtonEnabled = self.pasteboard.hasStrings
                }
            }
        }
    }
}

// MARK: - Actions

extension ImportKeyViewController {
    private func proceedToKeyImportFromFile() {
//        let documentInteractionController = UIDocumentBrowserViewController()
//        documentInteractionController.allowsDocumentCreation = false
//        documentInteractionController.allowsPickingMultipleItems = false
//        documentInteractionController.browserUserInterfaceStyle = .light
//        documentInteractionController.view.tintColor = .main
//        documentInteractionController.allowedContentTypes

        let documentInteractionController = UIDocumentPickerViewController(documentTypes: [
            "public.text",
            "public.plain-text",
            "public.jpeg",
            "public.html",
            "public.folders"
        ], in: .open)


        present(documentInteractionController, animated: true, completion: nil)
    }

    func proceedToKeyImportFromPasteboard() {

    }
}

// MARK: - UIDocumentInteractionControllerDelegate

extension ImportKeyViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        guard let navVC = self.navigationController else {
            return self
        }
        return navVC
    }
}
