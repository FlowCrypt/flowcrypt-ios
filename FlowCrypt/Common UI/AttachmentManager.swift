//
//  AttachmentManager.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 05.11.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

@MainActor
protocol AttachmentManagerType {
    func download(_ file: FileType) async
}

final class AttachmentManager: NSObject {
    private weak var controller: UIViewController?
    private let filesManager: FilesManagerType

    init(
        controller: UIViewController,
        filesManager: FilesManagerType
    ) {
        self.controller = controller
        self.filesManager = filesManager
    }

    @MainActor
    private func showFileSharedAlert(with url: URL) {
        controller?.showAlertWithAction(
            title: "message_attachment_saved_successfully_title".localized,
            message: "message_attachment_saved_successfully_message".localized,
            actionButtonTitle: "open".localized,
            onAction: { _ in UIApplication.shared.open(url) }
        )
    }

    @MainActor
    private func openDocumentsController(from url: URL) {
        let documentController = UIDocumentPickerViewController(forExporting: [url])
        documentController.delegate = self
        present(documentController, animated: true, completion: nil)
    }
}

extension AttachmentManager: AttachmentManagerType {

    func download(_ file: FileType) async {
        do {
            let url = try filesManager.save(file: file)
            openDocumentsController(from: url)
        } catch {
            controller?.showToast(
                "\("message_attachment_saved_with_error".localized) \(error.localizedDescription)"
            )
        }
    }
}

// MARK: - FilesManagerPresenter

extension AttachmentManager: FilesManagerPresenter {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        controller?.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}

// MARK: - UIDocumentPickerDelegate

extension AttachmentManager: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let savedUrl = urls.first,
              let sharedDocumentUrl = savedUrl.sharedDocumentURL else {
            return
        }
        showFileSharedAlert(with: sharedDocumentUrl)
    }
}
