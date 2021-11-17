//
//  FilesManager.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 16.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Combine
import UIKit

protocol FileType {
    var name: String { get }
    var size: Int { get }
    var data: Data { get }
}

protocol FilesManagerPresenter {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}

protocol FilesManagerType {
    func save(file: FileType) -> Future<URL, Error>
    func saveToFilesApp(file: FileType, from viewController: FilesManagerPresenter & UIDocumentPickerDelegate) -> AnyPublisher<Void, Error>

    @discardableResult
    func selectFromFilesApp(from viewController: FilesManagerPresenter & UIDocumentPickerDelegate) -> Future<Void, Error>

    func saveLocally(file: FileType) -> URL?
    func remove(file: FileType)
}

class FilesManager: FilesManagerType {

    private let documentsDirectoryURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }()
    private var cancellable = Set<AnyCancellable>()

    private let queue: DispatchQueue = DispatchQueue.global(qos: .background)

    func save(file: FileType) -> Future<URL, Error> {
        Future<URL, Error> { [weak self] future in
            guard let self = self else {
                future(.failure(AppErr.nilSelf))
                return
            }

            let url = self.documentsDirectoryURL.appendingPathComponent(file.name)
            self.queue.async {

                do {
                    try file.data.write(to: url)
                    future(.success(url))
                } catch {
                    future(.failure(error))
                }
            }
        }
    }

    func saveToFilesApp(
        file: FileType,
        from viewController: FilesManagerPresenter & UIDocumentPickerDelegate
    ) -> AnyPublisher<Void, Error> {
        return self.save(file: file)
            .flatMap { url in
                Future<Void, Error> { future in
                    DispatchQueue.main.async {
                        let documentController = UIDocumentPickerViewController(forExporting: [url])
                        documentController.delegate = viewController
                        viewController.present(documentController, animated: true, completion: nil)
                        future(.success(()))
                    }
                }
            }
            .eraseToAnyPublisher()
    }

    @discardableResult
    func selectFromFilesApp(
        from viewController: FilesManagerPresenter & UIDocumentPickerDelegate
    ) -> Future<Void, Error> {
        Future<Void, Error> { future in
            DispatchQueue.main.async {
                let documentController = UIDocumentPickerViewController(
                    documentTypes: ["public.data"], in: .import
                )
                documentController.delegate = viewController
                viewController.present(documentController, animated: true, completion: nil)
                future(.success(()))
            }
        }
    }

    func saveLocally(file: FileType) -> URL? {
        let documentDirectory = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        guard let localPath = documentDirectory?.path.appending("/\(file.name)")
        else { return nil }
        let url = URL(fileURLWithPath: localPath)
        try? file.data.write(to: url)
        return url
    }

    func remove(file: FileType) {
        let fileManager = FileManager.default
        let documentDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        guard let localPath = documentDirectory?.path.appending("/\(file.name)")
        else { return }
        let url = URL(fileURLWithPath: localPath)
        try? fileManager.removeItem(at: url)
    }
}
