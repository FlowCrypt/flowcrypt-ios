//
//  MessageAttachment.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 25/11/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Photos
import UIKit

struct MessageAttachment: Equatable, Hashable, FileType {
    let id: Identifier
    let name: String
    let estimatedSize: Int?
    let mimeType: String?

    var data: Data?
}

extension MessageAttachment {
    init?(cameraSourceMediaInfo: [UIImagePickerController.InfoKey: Any]) {
        guard let image = cameraSourceMediaInfo[.originalImage] as? UIImage,
              let data = image.jpegData(compressionQuality: 0.95)
        else {
            return nil
        }

        self.init(name: "\(UUID().uuidString).jpg", data: data)
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

        self.init(name: fileURL.lastPathComponent, data: data)
    }

    init(name: String, data: Data) {
        self.id = Identifier.random
        self.name = name
        self.data = data
        self.estimatedSize = data.count
        self.mimeType = name.mimeType
    }
}

extension MessageAttachment {
    func toSendableMsgAttachment() -> SendableMsg.Attachment {
        return SendableMsg.Attachment(name: name, type: type, base64: data?.base64EncodedString() ?? "")
    }
}
