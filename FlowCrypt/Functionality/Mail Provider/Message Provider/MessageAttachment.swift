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

    var treatAs: String?
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

    init(name: String, data: Data, mimeType: String? = nil, treatAs: String? = nil) {
        self.id = .random
        self.name = name
        self.data = data
        self.estimatedSize = data.count
        self.mimeType = mimeType ?? name.mimeType
        self.treatAs = treatAs
    }

    init?(attMeta: MsgBlock.AttMeta) {
        guard let data = Data(base64Encoded: attMeta.data.data()) else {
            return nil
        }

        self.init(name: attMeta.name, data: data, mimeType: attMeta.type, treatAs: attMeta.treatAs)
    }
}

extension MessageAttachment {
    var sendableMsgAttachment: SendableMsg.Attachment {
        .init(name: name, type: type, base64: data?.base64EncodedString() ?? "")
    }

    var supportsPreview: Bool {
        mimeTypesWithPreview.contains(type)
    }

    func toDict(msgId: Identifier) -> [String: Any?] {
        ["id": id.stringId,
         "msgId": msgId.stringId,
         "type": mimeType,
         "name": name,
         "length": estimatedSize]
    }
}

private let mimeTypesWithPreview = [
    "application/excel", "application/vnd.ms-excel", "application/mspowerpoint", "application/vnd.ms-powerpoint",
    "application/powerpoint", "application/msword", "application/vnd.ms-word",
    "application/json", "application/octet-stream", "application/pdf", "application/rtf",
    "application/vnd.apple.keynote", "application/vnd.apple.numbers", "application/vnd.apple.pages",
    "application/vnd.openxmlformats-officedocument.presentationml.slideshow",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/x-sh", "application/x-javascript", "application/xhtml+xml", "application/xml",
    "audio/aac", "audio/m4a", "audio/midi", "audio/mpeg", "audio/mpeg3", "audio/ogg", "audio/x-midi", "audio/wav", "audio/webm",
    "image/gif", "image/jpeg", "image/pjpeg", "image/png", "image/svg+xml", "image/tiff", "image/webp",
    "text/css", "text/csv", "text/html", "text/javascript", "text/plain", "text/xml",
    "video/avi", "video/mp4", "video/mpeg", "video/msvideo", "video/ogg", "video/quicktime", "video/webm", "video/x-msvideo"
]
