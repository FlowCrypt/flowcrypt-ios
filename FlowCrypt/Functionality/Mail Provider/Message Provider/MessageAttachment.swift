//
//  MessageAttachment.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 25/11/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Photos
import UIKit

struct MessageAttachment: Equatable, Hashable {
    let id: Identifier?
    let name: String
    var data: Data?
    let estimatedSize: Int?
//    let isEncrypted: Bool
}

extension MessageAttachment {
    init?(cameraSourceMediaInfo: [UIImagePickerController.InfoKey: Any]) {
        guard let image = cameraSourceMediaInfo[.originalImage] as? UIImage,
              let data = image.jpegData(compressionQuality: 0.95) else {
            return nil
        }

        self.id = nil
        self.name = "\(UUID().uuidString).jpg"
        self.data = data
        self.estimatedSize = nil
//        self.isEncrypted = false
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

        self.id = nil
        self.name = fileURL.lastPathComponent
        self.data = data
        self.estimatedSize = nil
//        self.isEncrypted = false
    }

    var isEncrypted: Bool {
        name.hasSuffix(".pgp")
    }
    var size: Int { data?.count ?? estimatedSize ?? 0 }
    var formattedSize: String {
        ByteCountFormatter().string(fromByteCount: Int64(size))
    }
    var type: String { name.mimeType }
}

extension MessageAttachment {
    func toSendableMsgAttachment() -> SendableMsg.Attachment {
        return SendableMsg.Attachment(name: name, type: type, base64: data?.base64EncodedString() ?? "")
    }
}

struct MessageAttachmentMetadata: Hashable {
    let id: Identifier
    let name: String
    let size: Float
}

extension MessageAttachmentMetadata {
    var formattedSize: String {
        ByteCountFormatter().string(fromByteCount: Int64(size))
    }
    var isEncrypted: Bool {
        name.hasSuffix(".pgp")
    }
}
