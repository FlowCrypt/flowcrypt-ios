//
//  ImportKeyViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 14.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import MobileCoreServices

final class ImportKeyViewController: ASViewController<TableNode> {
    private enum Parts: Int, CaseIterable {
        case title, description, fileImport, pasteBoardImport

        var indexPath: IndexPath {
            IndexPath(row: rawValue, section: 0)
        }
    }

    private let decorator: EnterPassPhraseViewDecoratorType
    private let pasteboard: UIPasteboard
    private let dataService: DataServiceType
    private let core: Core

    private var userInfoMessage = "" {
        didSet { updateSubtitle() }
    }

    init(
        decorator: EnterPassPhraseViewDecoratorType = EnterPassPhraseViewDecorator(),
        pasteboard: UIPasteboard = UIPasteboard.general,
        core: Core = Core.shared,
        dataService: DataServiceType = DataService.shared
    ) {
        self.pasteboard = pasteboard
        self.decorator = decorator
        self.dataService = dataService
        self.core = core
        super.init(node: TableNode())
    }

    required init?(coder _: NSCoder) {
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        userInfoMessage = ""
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *) else { return }
        node.reloadData()
    }

    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        title = decorator.sceneTitle
    }

    private func updateSubtitle() {
        DispatchQueue.main.async {
            self.node.reloadRows(at: [Parts.description.indexPath], with: .fade)
        }
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension ImportKeyViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        return Parts.allCases.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .title:
                return SetupTitleNode(
                    title: self.decorator.title,
                    insets: self.decorator.titleInsets
                )
            case .description:
                return SetupTitleNode(
                    title: self.decorator.subtitleStyle(self.userInfoMessage),
                    insets: self.decorator.subTitleInset
                )
            case .fileImport:
                return ButtonCellNode(
                    title: self.decorator.fileImportTitle,
                    insets: self.decorator.buttonInsets
                ) { [weak self] in
                    self?.proceedToKeyImportFromFile()
                }
            case .pasteBoardImport:
                return ButtonCellNode(
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
        let acceptableDocumentTypes = [
            String(kUTTypeText),
            String(kUTTypePlainText),
            String(kUTTypeUTF8PlainText),
            String(kUTTypeUTF16ExternalPlainText),
            String(kUTTypeUTF16PlainText),
            String(kUTTypeItem),
            String(kUTTypeData)
        ]
        let documentInteractionController = UIDocumentPickerViewController(
            documentTypes: acceptableDocumentTypes,
            in: .open
        ).then {
            $0.delegate = self
            $0.allowsMultipleSelection = false
        }

        present(documentInteractionController, animated: true, completion: nil)
    }

    private func proceedToKeyImportFromPasteboard() {
        guard let armoredKey = pasteboard.string else { return }
        parseFetched(data: Data(armoredKey.utf8))
    }

    private func parseFetched(data keyData: Data) {
        do {
            let keys = try core.parseKeys(armoredOrBinary: keyData)
            let privateKey = keys.keyDetails.filter { $0.private != nil }
            let user = dataService.email ?? "unknown_title".localized

            if privateKey.isEmpty {
                userInfoMessage = "import_no_backups_clipboard".localized + user
            } else {
                userInfoMessage = "Found \(privateKey.count) key\(privateKey.count > 1 ? "s" : "")"
                proceedToPassPhrase(with: user, keys: privateKey)
            }
        } catch {
            userInfoMessage = error.localizedDescription
        }
    }

    private func proceedToPassPhrase(with email: String, keys: [KeyDetails]) {
        let viewController = EnterPassPhraseViewController(
            decorator: decorator,
            email: email,
            fetchedKeys: keys
        )
        let animationDuration = 1.0

        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { [weak self] in
            self?.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

// MARK: - UIDocumentPickerDelegate

extension ImportKeyViewController: UIDocumentPickerDelegate {
    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let pickedURL = urls.first else { return }
        hanldePicked(document: pickedURL)
    }

    private func hanldePicked(document url: URL) {
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let document = Document(fileURL: url)
        document.open { [weak self] success in
            guard success else { assertionFailure("Failed to open doc"); return }
            guard let metadata = document.data else { assertionFailure("Failed to fetch data"); return }
            self?.parseFetched(data: metadata)
        }
    }
}
