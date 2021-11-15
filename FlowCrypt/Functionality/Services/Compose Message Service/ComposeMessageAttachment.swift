//
//  ComposeMessageAttachment.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 24.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit
import Photos

struct ComposeMessageAttachment: Equatable {
    let name: String
    let size: Int
    let data: Data
    let type: String
    var humanReadableSizeString: String {
        return ByteCountFormatter().string(fromByteCount: Int64(self.size))
    }
}

extension ComposeMessageAttachment {

    init?(cameraSourceMediaInfo: [UIImagePickerController.InfoKey: Any]) {
        guard let image = cameraSourceMediaInfo[.originalImage] as? UIImage,
              let data = image.jpegData(compressionQuality: 1) else {
            return nil
        }

        self.name = "\(UUID().uuidString).jpg"
        self.data = data
        self.size = data.count
        self.type = "image/jpg"
    }

    init?(fileURL: URL) {
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        self.name = fileURL.lastPathComponent
        self.data = data
        self.size = data.count
        self.type = fileURL.mimeType
    }

    func toSendableMsgAttachment() -> SendableMsg.Attachment {
        return SendableMsg.Attachment( name: self.name, type: self.type, base64: self.data.base64EncodedString())
    }
}
