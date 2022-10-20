//
//  ComposeViewController+Picker.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import PhotosUI
import UIKit

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension ComposeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true, completion: nil)

        let composeMessageAttachment: MessageAttachment?
        switch picker.sourceType {
        case .camera:
            composeMessageAttachment = MessageAttachment(cameraSourceMediaInfo: info)
        default:
            showAlert(message: "files_picking_no_other_source".localized)
            return
        }

        guard let attachment = composeMessageAttachment else {
            showAlert(message: "files_picking_photos_error_message".localized)
            return
        }
        appendAttachmentIfAllowed(attachment)
        reload(sections: [.attachments])
    }

    private func appendAttachmentIfAllowed(_ attachment: MessageAttachment) {
        let totalSize = contextToSend.attachments.map(\.size).reduce(0, +) + attachment.size
        if totalSize > GeneralConstants.Global.attachmentSizeLimit {
            showToast("files_picking_size_error_message".localized)
        } else {
            contextToSend.attachments.append(attachment)
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ComposeViewController: PHPickerViewControllerDelegate {
    nonisolated func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        Task {
            await picker.dismiss(animated: true)
            await handleResults(results)
        }
    }

    private func handleResults(_ results: [PHPickerResult]) {
        guard let itemProvider = results.first?.itemProvider else { return }

        enum MediaType: String {
            case image, movie

            var identifier: String { "public.\(rawValue)" }
        }

        let isVideo = itemProvider.hasItemConformingToTypeIdentifier(MediaType.movie.identifier)
        let mediaType: MediaType = isVideo ? .movie : .image

        itemProvider.loadFileRepresentation(
            forTypeIdentifier: mediaType.identifier,
            completionHandler: { [weak self] url, error in
                DispatchQueue.main.async {
                    self?.handleRepresentation(
                        url: url,
                        error: error,
                        isVideo: isVideo
                    )
                }
            }
        )
    }

    private func handleRepresentation(url: URL?, error: Error?, isVideo: Bool) {
        guard
            let url,
            let composeMessageAttachment = MessageAttachment(fileURL: url)
        else {
            let message = isVideo
                ? "files_picking_videos_error_message".localized
                : "files_picking_photos_error_message".localized
            let errorMessage = error.flatMap { "." + $0.localizedDescription } ?? ""
            showAlert(message: message + errorMessage)
            return
        }

        appendAttachmentIfAllowed(composeMessageAttachment)
        reload(sections: [.attachments])
    }
}

// MARK: - UIDocumentPickerDelegate
extension ComposeViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileUrl = urls.first,
              let attachment = MessageAttachment(fileURL: fileUrl)
        else {
            showAlert(message: "files_picking_files_error_message".localized)
            return
        }
        appendAttachmentIfAllowed(attachment)
        reload(sections: [.attachments])
    }
}
