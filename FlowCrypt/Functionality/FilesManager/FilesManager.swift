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
    var data: Data { get }
}

extension FileType {
    var size: Int { data.count }
    var formattedSize: String {
        ByteCountFormatter().string(fromByteCount: Int64(size))
    }
    var type: String { name.mimeType }
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
    private let documentsDirectoryURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }()
}

extension FilesManager: FilesManagerType {
    func save(file: FileType) throws -> URL {
        let url = documentsDirectoryURL.appendingPathComponent(file.name)
        try file.data.write(to: url)
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
