//
//  AttachmentManager.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 05.11.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit
import Combine

protocol AttachmentManagerType {
    func open(_ attachment: MessageAttachment)
}

final class AttachmentManager: NSObject {
    private let controller: UIViewController
    private let filesManager: FilesManagerType
    private var cancellable = Set<AnyCancellable>()

    init(controller: UIViewController,
         filesManager: FilesManagerType) {
        self.controller = controller
        self.filesManager = filesManager
    }

    private func showFileSharedAlert(with url: URL) {
        let alert = UIAlertController(
            title: "message_attachment_saved_successfully_title".localized,
            message: "message_attachment_saved_successfully_message".localized,
            preferredStyle: .alert
        )

        let cancel = UIAlertAction(title: "cancel".localized, style: .cancel) { _ in }
        let open = UIAlertAction(title: "open".localized, style: .default) { _ in
            UIApplication.shared.open(url)
        }

        alert.addAction(cancel)
        alert.addAction(open)

        controller.present(alert, animated: true)
    }
}

extension AttachmentManager: AttachmentManagerType {
    func open(_ attachment: MessageAttachment) {
        filesManager.saveToFilesApp(file: attachment, from: self)
            .sinkFuture(
                receiveValue: {},
                receiveError: { error in
                    self.controller.showToast(
                        "\("message_attachment_saved_with_error".localized) \(error.localizedDescription)"
                    )
                }
            )
            .store(in: &self.cancellable)
    }
}

// MARK: - FilesManagerPresenter

extension AttachmentManager: FilesManagerPresenter {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        controller.present(viewControllerToPresent, animated: flag, completion: completion)
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
