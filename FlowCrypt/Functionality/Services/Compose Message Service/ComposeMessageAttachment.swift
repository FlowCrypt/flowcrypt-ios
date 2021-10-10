//
//  ComposeMessageAttachment.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 24.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit
import Photos

struct ComposeMessageAttachment {
    let name: String
    let size: Int
    let data: Data
    let type: String
}

extension ComposeMessageAttachment {
    init?(librarySourceMediaInfo: [UIImagePickerController.InfoKey: Any]) {
        guard let mediaType = librarySourceMediaInfo[.mediaType] as? String else {
             return nil
        }

        let urlKey: UIImagePickerController.InfoKey
        switch mediaType {
        case PhotosManager.MediaType.image:
            urlKey = .imageURL
        case PhotosManager.MediaType.video:
            urlKey = .mediaURL
        default: return nil
        }

        do {
            guard let url = librarySourceMediaInfo[urlKey] as? URL else { return nil }
            let data = try Data(contentsOf: url)

            self.name = url.lastPathComponent
            self.data = data
            self.size = data.count
            self.type = url.lastPathComponent.mimeType
        } catch {
            return nil
        }
    }

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
}
