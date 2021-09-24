//
//  ComposeMessageAttachment.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 24.09.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
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
        guard let image = librarySourceMediaInfo[.originalImage] as? UIImage,
              let data = image.pngData(),
              let asset = librarySourceMediaInfo[.phAsset] as? PHAsset else {
            return nil
        }
        let assetResources = PHAssetResource.assetResources(for: asset)

        guard let fileName = assetResources.first?.originalFilename else {
            return nil
        }

        self.name = "\(fileName).pgp"
        self.data = data
        self.size = data.count
        self.type = "text/plain"
    }

    init?(cameraSourceMediaInfo: [UIImagePickerController.InfoKey: Any]) {
        guard let image = cameraSourceMediaInfo[.originalImage] as? UIImage,
              let data = image.pngData() else {
            return nil
        }

        self.name = "\(UUID().uuidString).png.pgp"
        self.data = data
        self.size = data.count
        self.type = "text/plain"
    }

    init?(fileURL: URL) {
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        self.name = "\(fileURL.lastPathComponent).pgp"
        self.data = data
        self.size = data.count
        self.type = fileURL.mimeType
    }
}
