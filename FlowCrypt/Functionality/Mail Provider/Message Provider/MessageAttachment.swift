//
//  MessageAttachment.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 25/11/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Photos
import UIKit

struct MessageAttachment: FileType, Equatable {
    let name: String
    let data: Data
}

extension MessageAttachment {
    init?(cameraSourceMediaInfo: [UIImagePickerController.InfoKey: Any]) {
        guard let image = cameraSourceMediaInfo[.originalImage] as? UIImage,
              let data = image.jpegData(compressionQuality: 1) else {
            return nil
        }

        self.name = "\(UUID().uuidString).jpg"
        self.data = data
    }

    init?(fileURL: URL) {
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        self.name = fileURL.lastPathComponent
        self.data = data
    }
}

extension MessageAttachment {
    func toSendableMsgAttachment() -> SendableMsg.Attachment {
        return SendableMsg.Attachment(name: name, type: type, base64: data.base64EncodedString())
    }
}
