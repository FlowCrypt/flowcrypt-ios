//
//  ComposeViewController+Attachment.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

// MARK: - Attachments sheet handling
extension ComposeViewController {
    internal func openAttachmentsInputSourcesSheet() {
        let alert = UIAlertController(
            title: "files_picking_select_input_source_title".localized,
            message: nil,
            preferredStyle: .actionSheet
        ).popoverPresentation(style: .centred(view))

        alert.addAction(
            UIAlertAction(
                title: "files_picking_camera_input_source".localized,
                style: .default,
                handler: { [weak self] _ in self?.takePhoto() }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: "files_picking_photo_library_source".localized,
                style: .default,
                handler: { [weak self] _ in self?.selectPhoto() }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: "files_picking_files_source".localized,
                style: .default,
                handler: { [weak self] _ in self?.selectFromFilesApp() }
            )
        )
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel))
        present(alert, animated: true, completion: nil)
    }

    internal func takePhoto() {
        Task {
            do {
                try await photosManager.takePhoto(from: self)
            } catch {
                showNoAccessToCameraAlert()
            }
        }
    }

    private func selectPhoto() {
        Task {
            await photosManager.selectPhoto(from: self)
        }
    }

    private func selectFromFilesApp() {
        Task {
            await filesManager.selectFromFilesApp(from: self)
        }
    }

    private func showNoAccessToCameraAlert() {
        let alert = UIAlertController(
            title: "files_picking_no_camera_access_error_title".localized,
            message: "files_picking_no_camera_access_error_message".localized,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(
            title: "ok".localized,
            style: .cancel
        ) { _ in }
        let settingsAction = UIAlertAction(
            title: "settings".localized,
            style: .default
        ) { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }
        alert.addAction(okAction)
        alert.addAction(settingsAction)

        present(alert, animated: true, completion: nil)
    }
}
