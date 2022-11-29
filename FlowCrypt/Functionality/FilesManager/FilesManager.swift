//
//  FilesManager.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 16.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

protocol FileType {
    var name: String { get }
    var estimatedSize: Int? { get }
    var mimeType: String? { get }

    var treatAs: String? { get set }
    var data: Data? { get set }
}

extension FileType {
    var size: Int { data?.count ?? estimatedSize ?? 0 }
    var formattedSize: String {
        ByteCountFormatter().string(fromByteCount: Int64(size))
    }

    var type: String { mimeType ?? name.mimeType }
    var isEncrypted: Bool {
        treatAs == "encryptedFile" || name.hasSuffix(".pgp") || name.hasSuffix(".asc")
    }
}

protocol FilesManagerPresenter {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}

protocol FilesManagerType {
    typealias Controller = FilesManagerPresenter & UIDocumentPickerDelegate

    func save(file: FileType) throws -> URL

    @MainActor
    func selectFromFilesApp(from viewController: Controller) async
}

final class FilesManager {
    private let documentsDirectoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
}

extension FilesManager: FilesManagerType {
    func save(file: FileType) throws -> URL {
        let url = documentsDirectoryURL.appendingPathComponent(file.name)
        try file.data?.write(to: url)
        return url
    }

    func selectFromFilesApp(from viewController: Controller) async {
        let documentController = UIDocumentPickerViewController(
            forOpeningContentTypes: [.data]
        )
        documentController.delegate = viewController
        viewController.present(documentController, animated: true, completion: nil)
    }
}
