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
    var size: Int {
        data.count
    }
    var formattedSize: String {
        ByteCountFormatter().string(fromByteCount: Int64(size))
    }
    var type: String {
        name.mimeType
    }
    var fileName: String {
        guard let sufix = name.components(separatedBy: ".").last else {
            return name
        }
        return name + "." + sufix
    }
}

protocol FilesManagerPresenter {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}

protocol FilesManagerType {
    typealias Controller = FilesManagerPresenter & UIDocumentPickerDelegate

    func save(file: FileType) async throws -> URL

    @MainActor
    func saveToFilesApp(file: FileType, from viewController: Controller) async throws

    @MainActor
    func selectFromFilesApp(from viewController: Controller) async
}

final class FilesManager {
    private let documentsDirectoryURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }()

    private let queue: DispatchQueue = DispatchQueue.global(qos: .background)
}

extension FilesManager: FilesManagerType {
    func save(file: FileType) async throws -> URL {
        let url = self.documentsDirectoryURL.appendingPathComponent(file.fileName)

        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    try file.data.write(to: url)
                    continuation.resume(returning: url)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func saveToFilesApp(file: FileType, from viewController: Controller) async throws {
        let url = try await save(file: file)
        let documentController = UIDocumentPickerViewController(forExporting: [url])
        documentController.delegate = viewController
        viewController.present(documentController, animated: true, completion: nil)
    }

    func selectFromFilesApp(from viewController: Controller) async {
        let documentController = UIDocumentPickerViewController(
            documentTypes: ["public.data"], in: .import
        )
        documentController.delegate = viewController
        viewController.present(documentController, animated: true, completion: nil)
    }
}
