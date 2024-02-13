//
//  SetupManuallyImportKeyViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 14.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

/**
 * Controller which is responsible for importing key from a file or to paste it from pasteBoard
 * - User can reach this screen:
 *           - when there are no backups found from **SetupInitialViewController**  in setup flow
 *           - or from key settings **KeySettingsViewController**
 * - After key is added user will be redirected to **SetupManuallyEnterPassPhraseViewController**
 */
final class SetupManuallyImportKeyViewController: TableNodeViewController {
    private enum Parts: Int, CaseIterable {
        case title, description, fileImport, pasteBoardImport

        var indexPath: IndexPath {
            IndexPath(row: rawValue, section: 0)
        }
    }

    private let appContext: AppContextWithUser
    private let decorator: SetupViewDecorator
    private let pasteboard: UIPasteboard

    private var userInfoMessage = "" {
        didSet { updateSubtitle() }
    }

    init(
        appContext: AppContextWithUser,
        decorator: SetupViewDecorator = SetupViewDecorator(),
        pasteboard: UIPasteboard = UIPasteboard.general
    ) {
        self.appContext = appContext
        self.pasteboard = pasteboard
        self.decorator = decorator
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.barStyle = .black
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        userInfoMessage = ""
    }

    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        title = decorator.sceneTitle(for: .importKey)
    }

    private func updateSubtitle() {
        node.reloadRows(at: [Parts.description.indexPath], with: .fade)
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension SetupManuallyImportKeyViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .title:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: self.decorator.title(for: .importKey),
                        insets: self.decorator.insets.titleInset,
                        backgroundColor: .backgroundColor
                    )
                )
            case .description:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: self.decorator.subtitleStyle(self.userInfoMessage),
                        insets: self.decorator.insets.subTitleInset,
                        backgroundColor: .backgroundColor
                    )
                )
            case .fileImport:
                let input = ButtonCellNode.Input(
                    title: self.decorator.buttonTitle(for: .fileImport)
                )
                return ButtonCellNode(input: input) { [weak self] in
                    self?.proceedToKeyImportFromFile()
                }
            case .pasteBoardImport:
                let input = ButtonCellNode.Input(
                    title: self.decorator.buttonTitle(for: .pasteBoard)
                )
                return ButtonCellNode(input: input) { [weak self] in
                    guard let self else { return }
                    Task {
                        do {
                            try await self.proceedToKeyImportFromPasteboard()
                        } catch {
                            self.userInfoMessage = error.localizedDescription
                        }
                    }
                }
                .then {
                    $0.isButtonEnabled = self.pasteboard.hasStrings
                }
            }
        }
    }
}

// MARK: - Actions

extension SetupManuallyImportKeyViewController {
    private func proceedToKeyImportFromFile() {
        let acceptableDocumentTypes: [UTType] = [
            .text,
            .plainText,
            .utf8PlainText,
            .utf8TabSeparatedText,
            .utf16PlainText,
            .utf16ExternalPlainText,
            .item,
            .data
        ]
        let documentInteractionController = UIDocumentPickerViewController(
            forOpeningContentTypes: acceptableDocumentTypes
        ).then {
            $0.delegate = self
            $0.allowsMultipleSelection = false
        }

        present(documentInteractionController, animated: true, completion: nil)
    }

    private func proceedToKeyImportFromPasteboard() async throws {
        guard let armoredKey = pasteboard.string else { return }
        try await parseUserProvided(data: Data(armoredKey.utf8))
    }

    private func parseUserProvided(data keyData: Data) async throws {
        let keys = try await Core.shared.parseKeys(armoredOrBinary: keyData)
        let privateKey = keys.keyDetails.filter { $0.private != nil }
        let user = appContext.user.email
        if privateKey.isEmpty {
            userInfoMessage = "import_no_backups_clipboard".localized + user
        } else {
            userInfoMessage = "Found %@ key(s)".localizePluralsWithArguments(privateKey.count)
            proceedToPassPhrase(with: user, keys: privateKey)
        }
    }

    private func proceedToPassPhrase(with email: String, keys: [KeyDetails]) {
        let viewController = SetupManuallyEnterPassPhraseViewController(
            appContext: appContext,
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

extension SetupManuallyImportKeyViewController: UIDocumentPickerDelegate {
    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let pickedURL = urls.first else { return }
        handlePicked(document: pickedURL)
    }

    private func handlePicked(document url: URL) {
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
            guard let self else { return }
            Task {
                do {
                    try await self.parseUserProvided(data: metadata)
                } catch {
                    self.userInfoMessage = error.localizedDescription
                }
            }
        }
    }
}
