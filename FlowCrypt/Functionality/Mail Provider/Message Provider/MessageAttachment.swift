//
//  MessageAttachment.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 25/11/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Photos
import UIKit

struct MessageAttachment: Equatable, FileType {
    let name: String
    let data: Data
    let isEncrypted: Bool
}

extension MessageAttachment {
    init?(cameraSourceMediaInfo: [UIImagePickerController.InfoKey: Any]) {
        guard let image = cameraSourceMediaInfo[.originalImage] as? UIImage,
              let data = image.jpegData(compressionQuality: 0.9) else {
            return nil
        }

        self.name = "\(UUID().uuidString).jpg"
        self.data = data
        self.isEncrypted = false
    }

    init?(fileURL: URL) {
        let shouldStopAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        self.name = fileURL.lastPathComponent
        self.data = data
        self.isEncrypted = false
    }
}

extension MessageAttachment {
    func toSendableMsgAttachment() -> SendableMsg.Attachment {
        return SendableMsg.Attachment(name: name, type: type, base64: data.base64EncodedString())
    }
}
