//
//  FilesManager.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 16.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

protocol FilesManagerPresenter {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}

protocol FilesManagerType {
    typealias Controller = FilesManagerPresenter & UIDocumentPickerDelegate

    func save(file: FileItem, options: Data.WritingOptions) throws -> URL

    @MainActor
    func saveToFilesApp(file: FileItem, from viewController: Controller) async throws

    @MainActor
    func selectFromFilesApp(from viewController: Controller) async
}

final class FilesManager {
    private let documentsDirectoryURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }()

    private let queue = DispatchQueue.global(qos: .background)
}

extension FilesManager: FilesManagerType {
    func save(file: FileItem, options: Data.WritingOptions = []) throws -> URL {
        let url = documentsDirectoryURL.appendingPathComponent(file.name)
        try file.data.write(to: url, options: options)
        return url
    }

    func read(fileName: String) throws -> Data {
        let url = self.documentsDirectoryURL.appendingPathComponent(fileName)
        return try Data(contentsOf: url)
    }

    func saveToFilesApp(file: FileItem, from viewController: Controller) throws {
        let url = try save(file: file)
        let documentController = UIDocumentPickerViewController(forExporting: [url])
        documentController.delegate = viewController
        viewController.present(documentController, animated: true, completion: nil)
    }

    func selectFromFilesApp(from viewController: Controller) async {
        let documentController = UIDocumentPickerViewController(
            forOpeningContentTypes: [.data]
        )
        documentController.delegate = viewController
        viewController.present(documentController, animated: true, completion: nil)
    }
}
