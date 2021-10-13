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

protocol FilesManagerType {
    func save(file: FileType) -> Future<URL, Error>
    func saveToFilesApp(file: FileType, from viewController: UIViewController & UIDocumentPickerDelegate) -> AnyPublisher<Void, Error>

    @discardableResult
    func selectFromFilesApp(from viewController: UIViewController & UIDocumentPickerDelegate) -> Future<Void, Error>
}

class FilesManager: FilesManagerType {

    private let documentsDirectoryURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }()
    private var cancellable = Set<AnyCancellable>()

    private let queue: DispatchQueue = DispatchQueue.global(qos: .background)

    func save(file: FileType) -> Future<URL, Error> {
        Future<URL, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(AppErr.nilSelf))
                return
            }

            let url = self.documentsDirectoryURL.appendingPathComponent(file.name)
            self.queue.async {

                do {
                    try file.data.write(to: url)
                    promise(.success(url))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }

    func saveToFilesApp(
        file: FileType,
        from viewController: UIViewController & UIDocumentPickerDelegate
    ) -> AnyPublisher<Void, Error> {
        return self.save(file: file)
            .flatMap { url in
                Future<Void, Error> { promise in
                    DispatchQueue.main.async {
                        let documentController = UIDocumentPickerViewController(forExporting: [url])
                        documentController.delegate = viewController
                        viewController.present(documentController, animated: true)
                        promise(.success(()))
                    }
                }
            }
            .eraseToAnyPublisher()
    }

    @discardableResult
    func selectFromFilesApp(
        from viewController: UIViewController & UIDocumentPickerDelegate
    ) -> Future<Void, Error> {
        Future<Void, Error> { promise in
            DispatchQueue.main.async {
                let documentController = UIDocumentPickerViewController(
                    documentTypes: ["public.data"], in: .import
                )
                documentController.delegate = viewController
                viewController.present(documentController, animated: true)
                promise(.success(()))
            }
        }
    }
}
