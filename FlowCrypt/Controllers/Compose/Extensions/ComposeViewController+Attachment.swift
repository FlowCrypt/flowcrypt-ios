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
    func openAttachmentsInputSourcesSheet() {
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
        let publicKeyAction = UIAlertAction(
            title: "files_picking_public_key".localized,
            style: .default,
            handler: { [weak self] _ in self?.attachPublicKey() }
        )
        publicKeyAction.accessibilityIdentifier = "aid-attach-public-key"
        alert.addAction(publicKeyAction)
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel))
        present(alert, animated: true, completion: nil)
    }

    func takePhoto() {
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
        showAlertWithAction(
            title: "files_picking_no_camera_access_error_title".localized,
            message: "files_picking_no_camera_access_error_message".localized,
            actionButtonTitle: "settings".localized,
            onAction: { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
        )
    }

    private func attachPublicKey() {
        Task {
            do {
                let (publicKey, longid) = try await getLatestUsablePublicKey()

                guard let publicKeyData = publicKey.data(using: .utf8) else {
                    throw AppErr.general("Failed to convert public key to data")
                }

                let attachment = MessageAttachment(
                    name: "0x\(longid).asc",
                    data: publicKeyData,
                    mimeType: "application/pgp-keys"
                )

                appendAttachmentIfAllowed(attachment)
                reload(sections: [.attachments])
            } catch {
                showAlert(message: "Failed to retrieve public key: \(error.localizedDescription)")
            }
        }
    }

    private func getLatestUsablePublicKey() async throws -> (publicKey: String, longid: String) {
        let userEmail = contextToSend.sender
        let keypairs = try await appContext.keyAndPassPhraseStorage.getKeypairsWithPassPhrases(email: userEmail)

        guard keypairs.isNotEmpty else {
            throw AppErr.general("No keypair found for \(userEmail)")
        }

        let keyDetailsList = try await KeyMethods().parseKeys(
            armored: keypairs.map(\.public)
        )

        let selectedKey = keyDetailsList
            .sorted { $0.created > $1.created }
            .first { $0.usableForEncryption && !$0.revoked && $0.isNotExpired }
            ?? keyDetailsList.max { $0.created < $1.created }

        guard let keyDetails = selectedKey,
              let keypair = keypairs.first(where: { $0.primaryFingerprint == (try? keyDetails.primaryFingerprint) }) else {
            throw AppErr.general("No valid keypair found for \(userEmail)")
        }

        return (keyDetails.public, keypair.primaryLongid)
    }
}
